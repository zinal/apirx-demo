# Тест конкурентного случайного чтения

Структура таблички:

```sql
 CREATE TABLE hashes(hash UInt64 NOT NULL, src Text, PRIMARY KEY(hash))
 WITH(AUTO_PARTITIONING_BY_LOAD=ENABLED,
      AUTO_PARTITIONING_MIN_PARTITIONS_COUNT=200,
      AUTO_PARTITIONING_MAX_PARTITIONS_COUNT=300,
      AUTO_PARTITIONING_PARTITION_SIZE_MB=500);
```

Настроечный файл для подключения программы apirx_test к YDB должен размещаться в текущем каталоге и иметь имя `apirx_test.xml`. Пример файла:

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
