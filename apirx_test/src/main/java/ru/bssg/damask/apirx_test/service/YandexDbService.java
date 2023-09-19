package ru.bssg.damask.apirx_test.service;

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.CompletableFuture;
import java.io.FileInputStream;
import java.util.Collections;
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
import tech.ydb.table.result.ValueReader;
import tech.ydb.table.transaction.TxControl;
import tech.ydb.table.values.ListValue;
import tech.ydb.table.values.PrimitiveValue;
import tech.ydb.table.values.StructValue;
import tech.ydb.table.values.Value;

/**
 * DB Service.
 *
 CREATE TABLE hashes(hash UInt64 NOT NULL, src Text, PRIMARY KEY(hash))
 WITH(AUTO_PARTITIONING_BY_LOAD=ENABLED,
      AUTO_PARTITIONING_MIN_PARTITIONS_COUNT=200,
      AUTO_PARTITIONING_MAX_PARTITIONS_COUNT=300,
      AUTO_PARTITIONING_PARTITION_SIZE_MB=100);
 */
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

    public Mono<List<String>> tokenizeRead(List<String> data) {
        String query = "DECLARE $input AS List<Struct<v:Uint64>>;" +
                "SELECT i.hash, x.src " +
                "FROM AS_TABLE($input) i " +
                "LEFT JOIN hashes x ON i.v=x.hash";
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
                long token = rs.getColumn(0).getUint64();
                ValueReader vr = rs.getColumn(1);
                if (vr.isOptionalItemPresent()) {
                    rres.add(String.valueOf(token) + "/" + vr.getText());
                } else {
                    rres.add(String.valueOf(token) + "/-");
                }
            }
            return rres;
        }));
    }

    public Mono<List<String>> tokenizeWrite(List<String> data) {
        String query = "DECLARE $input AS List<Struct<v:Uint64, s:Text>>;" +
                "UPSERT INTO hashes SELECT v AS hash, s AS src FROM AS_TABLE($input);";
        ArrayList<Value<?>> pack = new ArrayList<>();
        data.stream().forEach(s -> {
            pack.add(StructValue.of(
                    "v", PrimitiveValue.newUint64(LongHashFunction.xx().hashChars(s)),
                    "s", PrimitiveValue.newText(s)
            ));
        });
        Value<?>[] values = new Value<?>[pack.size()];
        pack.toArray(values);
        Params params = Params.of("$input", ListValue.of(values));
        CompletableFuture<Result<DataQueryResult>> r = retryCtx.supplyResult(session -> session.executeDataQuery(query, txControl, params));
        return Mono.fromFuture(r.thenApply(z -> {
            return Collections.emptyList();
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
