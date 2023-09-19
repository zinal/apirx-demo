package ru.bssg.damask.apirx_test.service;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.CompletableFuture;
import java.io.FileInputStream;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import net.openhft.hashing.LongHashFunction;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import tech.ydb.auth.iam.CloudAuthHelper;
import tech.ydb.core.Result;
import tech.ydb.core.grpc.GrpcTransport;
import tech.ydb.table.SessionRetryContext;
import tech.ydb.table.TableClient;
import tech.ydb.table.query.DataQueryResult;
import tech.ydb.table.query.Params;
import tech.ydb.table.result.ResultSetReader;
import tech.ydb.table.transaction.TxControl;
import tech.ydb.table.values.ListValue;
import tech.ydb.table.values.PrimitiveValue;
import tech.ydb.table.values.StructValue;
import tech.ydb.table.values.Value;

@Service
@Slf4j
public class YandexDbService {

    public static final String PROP_URL = "url";
    public static final String PROP_SAKEY_FILE = "sakey.file";
    public static final String PROP_POOL_MAX = "pool.max";

    private GrpcTransport transport;
    private TableClient tableClient;
    private SessionRetryContext retryCtx;
    private TxControl<?> txControl;
    private String database;

    public String getDatabase() {
        return database;
    }

    public Mono<List<String>> tokenizeManyTest(List<String> data) {
        String query = "DECLARE $input AS List<Struct<v:Uint64>>;" +
                "SELECT x.token " +
                "FROM AS_TABLE($input) i " +
                "INNER JOIN hashes x ON i.v=x.hash";
        ArrayList<Value<?>> pack = new ArrayList<>();
        data.stream().forEach(s -> pack.add(StructValue.of("v", PrimitiveValue.newUint64(LongHashFunction.xx().hashChars(s)))));
        Value<?>[] values = new Value<?>[pack.size()];
        pack.toArray(values);
        Params params = Params.of("$input", ListValue.of(values));
        CompletableFuture<Result<DataQueryResult>> r = retryCtx.supplyResult(session -> session.executeDataQuery(query, txControl, params));
        return Mono.fromFuture(r.thenApply(z -> {
            List<String> rres = new ArrayList<>();
            ResultSetReader rs = z.getValue().getResultSet(0);
            while (rs.next()) {
                rres.add(rs.getColumn(0).getText());
            }
            return rres;
        }));
    }

    @SneakyThrows
    @PostConstruct
    void init() {
        final Properties props = new Properties();
        try (FileInputStream fis = new FileInputStream("apirx_test.xml")) {
            props.loadFromXML(fis);
        }

        String connectionString = props.getProperty(PROP_URL);
        String saKeyFile = props.getProperty(PROP_SAKEY_FILE);
        int poolMax = Integer.parseInt(props.getProperty(PROP_POOL_MAX, "-1"));
        if (poolMax<1 || poolMax>1000) {
            poolMax = 100;
        }

        transport = GrpcTransport.forConnectionString(connectionString)
                .withAuthProvider(CloudAuthHelper.getServiceAccountFileAuthProvider(saKeyFile))
                .build();
        tableClient = TableClient.newClient(transport).sessionPoolSize(1, poolMax).build();
        database = transport.getDatabase();
        retryCtx = SessionRetryContext.create(tableClient).build();
        txControl = TxControl.serializableRw().setCommitTx(true);
        log.info("YDB service init");
    }

}
