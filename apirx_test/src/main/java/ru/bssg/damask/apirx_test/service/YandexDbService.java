package ru.bssg.damask.apirx_test.service;

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

import javax.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
public class YandexDbService {

    private final String serviceKeyJson = "{\n" +
            "  \"id\": \"ajef6h4l67sofb9ede0e\",\n" +
            "  \"service_account_id\": \"ajegoj8lbu8kh0cb8jpu\",\n" +
            "  \"created_at\": \"2023-08-30T08:22:59.262778565Z\",\n" +
            "  \"key_algorithm\": \"RSA_2048\",\n" +
            "  \"public_key\": \"-----BEGIN PUBLIC KEY-----\\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvX5H7qBYuDavBQGywDEA\\nsrzhZWtZMxtOC232PpKttTNqYFB7GZ+ulzcX+gbZk3yb+Mh4ATe4SzyoESyodeJT\\n5r+6knzVwcWNcqF40UBqJocS3QGFpclxjAzn5LHVfgzKT1/KcbS/DpgnCG8SyZax\\nNIjUPmLPjXoRpH7BO8US3tTi23f+Z00UIrKCUXIetKkgrguViaFcT3P0lrQcTG3G\\nrZ9lA/yUpenoL11UiuOPW2EfNeJLjdRJ1qpkzNFXMzC0o509nTLOmHO9hD4TRQL3\\nUoDnrt9ZxaTtrQD/nkMSlJxnrOZjOA/NLp1517M/HdeiQwlFQRBB0Yb32V+pBHX/\\n1QIDAQAB\\n-----END PUBLIC KEY-----\\n\",\n" +
            "  \"private_key\": \"-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC9fkfuoFi4Nq8F\\nAbLAMQCyvOFla1kzG04LbfY+kq21M2pgUHsZn66XNxf6BtmTfJv4yHgBN7hLPKgR\\nLKh14lPmv7qSfNXBxY1yoXjRQGomhxLdAYWlyXGMDOfksdV+DMpPX8pxtL8OmCcI\\nbxLJlrE0iNQ+Ys+NehGkfsE7xRLe1OLbd/5nTRQisoJRch60qSCuC5WJoVxPc/SW\\ntBxMbcatn2UD/JSl6egvXVSK449bYR814kuN1EnWqmTM0VczMLSjnT2dMs6Yc72E\\nPhNFAvdSgOeu31nFpO2tAP+eQxKUnGes5mM4D80unXnXsz8d16JDCUVBEEHRhvfZ\\nX6kEdf/VAgMBAAECggEAFBHkMf67LtWh32Sg51C5W3T8ZXbDdZGCiFze7B0yd0Lp\\nFSbpBtt+DSeJa1Ke6EtWJLks1qotY5Ca12jUtdmhG8s6SkodBL80/ktiZb1OEOMV\\nCSHgYyENHPF//R2luEpIAjSp1zW216efWLoU8hN7FM6aNjpWc8xWQocnVbqHh2Cz\\ntvY2rz5lfNgCU5Hie383hUvw6o1bEGKXTUQseh50DT9QcATk5XBP4BVM1AeWcsmC\\n5RtFHuNRO9Q3a30rYYbium1Y0eDgYH+LnyQwHrhMVbYFv9CJo3dwciOfbr2Y15jp\\n2UABqZXhtjBmCAaebtbajZSZLmmV5PZk5i0d96UYUQKBgQDaJ4iVE2/hVwSQbKa7\\n1o8mElAqrOhA98JzItvnWlgrlD0BxXcmN3Hexq3rIrPXR68n2Tk4K4/nqV2A5LF4\\nsWx6m9qzqpQ0S9TziHPkzYUUAOvt/nPaKFxRJDWl9b9Wecq2cnFFUxDrMHMFaD42\\nLOdBiPhi0frhtoB/8KVGGJbAhQKBgQDeXeBI64ZaiQRqTqKTUwZ1g35Vrv1n9DEp\\niJdL68CuXwxWanGEzlVR94TKMriorK3NHEdVMS5L6fUhzcnGfXp+AkMKnfrOEPyS\\np7xg3jVQPK9WZTyYy3JPAfbW5t63kglgFY3gWJQ2SnfvALnKsmWP1eC6DIJgAJuc\\nZBgkSa+LEQKBgESEtjlcaX91PVG/Tn8g3MUwa018EVaWetR+1mLL1XWaka7Evq+a\\nKoG2FVoNBD9RnIn/iCFETWaNo3igW710vIWl/gMASJxEVRZIfV4XzvyBbZjKmsii\\ndJxnqxH9JaObjTfQqhMEDARSq02/eAq7/8ZtptYi7ZGHKMUGaGKjxnWhAoGAdZdN\\nQSKT9RKaLCGTZbc1JjW4PFWCmlOPH/ikkbiFN3D6FETL7UAz7FmpdkfmUQSoEFyQ\\n+GM+qVR6ljq+JmI6waIuk9HBTPG8r01WmB9KMDk3O8fjiKWluFRAlZqXUpo+rPoZ\\nAfe1wRQWYmSO27sFbE/dPGXbGCuaHtTr01zIIRECgYAkMmArujKGIKC/KginNr22\\nA/mJOihXsN8RtxFfgDzVoBRKSsVABuwLmNzS09BTuoL4VYLCShLi8p2x+23Q1FhA\\nXCZ+7wHD/Ne+p6/ZJ4oMzC5CgpSaMqAv2QEwtcVQ4UG/VfNmk6IRETESEjZWt1t5\\nabkwNdD0rZZnxvNeVgVJLg==\\n-----END PRIVATE KEY-----\\n\"\n" +
            "}";
    private final String connectionString = "grpcs://lb.etnm4i05n0er13up5s6c.ydb.mdb.yandexcloud.net:2135/?database=/ru-central1/b1gog37qbqibtj94nm2d/etnm4i05n0er13up5s6c";

    private GrpcTransport transport;
    private TableClient tableClient;
    private SessionRetryContext retryCtx;
    private TxControl<?> txControl;

    public Mono<List<String>> tokenizeManyTest(List<String> data) {
        List<String> res = new ArrayList<>();
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
                rres.add(rs.getColumn("x.token").getText());
            }
            return rres;
        }));
    }

    @SneakyThrows
    @PostConstruct
    void init() {
        transport = GrpcTransport.forConnectionString(connectionString)
                .withAuthProvider(CloudAuthHelper.getServiceAccountJsonAuthProvider(serviceKeyJson))
                .build();
        tableClient = TableClient.newClient(transport).sessionPoolSize(500,1000).build();
        String database = transport.getDatabase();
        retryCtx = SessionRetryContext.create(tableClient).build();
        txControl = TxControl.serializableRw().setCommitTx(true);
        log.info("YDB service init");
    }

}
