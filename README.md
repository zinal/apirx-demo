# Тест конкурентного случайного чтения

Структура  используемой таблички:

```sql
 CREATE TABLE hashes(hash UInt64 NOT NULL, src Text, PRIMARY KEY(hash))
 WITH(AUTO_PARTITIONING_BY_LOAD=ENABLED,
      AUTO_PARTITIONING_MIN_PARTITIONS_COUNT=200,
      AUTO_PARTITIONING_MAX_PARTITIONS_COUNT=300,
      AUTO_PARTITIONING_PARTITION_SIZE_MB=500);
```

Обращения к YDB выполняются программой apirx_test, двоичный дистрибутив в виде jar-архива [доступен в разделе релизов](https://github.com/zinal/apirx-demo/releases/). Для работы программы apirx_test требуется OpenJDK 17 или выше (на более ранних не проверялось).

Настроечный файл для подключения к YDB при запуске программы apirx_test должен размещаться в текущем каталоге и иметь имя `apirx_test.xml`. Пример файла:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<entry key="url">grpc://ydb-d1:2136/?database=/Root/testdb</entry>
<entry key="auth.mode">NONE</entry> <!-- NONE, SAKEY, META, LOGIN -->
<entry key="auth.user">username</entry>
<entry key="auth.password">password</entry>
<entry key="sakey.file">sakey.json</entry>
<entry key="pool.max">1000</entry>
<!-- <entry key="ca.file">ca.crt</entry> -->
</properties>
```

Запуск программы apirx_test:

```bash
java -jar apirx_test-1.0-SNAPSHOT.jar
```

Генерация данных выполняется сценарием JMeter при работающей на том же хосте программе apirx_test:

```bash
./jmeter/bin/jmeter -n -t run-generate.jmx
```

Тест выполняется сценарием JMeter при работающей на том же хосте программе apirx_test:

```bash
./jmeter/bin/jmeter -n -t run-read.jmx
```

При выполнении сценария измеряется количество выполненных операций и средняя интенсивность их выполнения на каждом интервале и в целом за время выполнения теста. Данные выводятся на экран. При запуске тестов с нескольких хостов данные о средней пропускной способности каждого хоста необходимо суммировать при оценке суммарной пропускной способности.
