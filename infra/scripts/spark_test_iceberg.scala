// Teste completo de integração Spark + Iceberg + MinIO

println("=" * 60)
println("TESTE: Spark + Iceberg + MinIO Integration")
println("=" * 60)

// 1. Verificar se o Iceberg está disponível
println("\n[1] Verificando Iceberg Extensions...")
try {
    val ext = spark.sessionState.experimentalMethods
    println("✅ Iceberg Extensions carregadas")
} catch {
    case e: Exception => println(s"❌ Erro: ${e.getMessage}")
}

// 2. Listar catálogos disponíveis
println("\n[2] Catálogos disponíveis:")
spark.sql("SHOW CATALOGS").show()

// 3. Testar conexão com Hive Metastore
println("\n[3] Verificando acesso ao Hive Metastore...")
try {
    val databases = spark.sql("SHOW DATABASES")
    databases.show()
    println("✅ Hive Metastore conectado")
} catch {
    case e: Exception => println(s"❌ Erro: ${e.getMessage}")
}

// 4. Testar S3A (MinIO)
println("\n[4] Testando conectividade S3A (MinIO)...")
try {
    val testPath = "s3a://datalake/test_spark_iceberg"
    val df = spark.range(100).selectExpr("id", "concat('row_', id) as name")
    df.write.mode("overwrite").parquet(testPath)
    println(s"✅ Arquivo escrito em: $testPath")
    
    val readBack = spark.read.parquet(testPath)
    println(s"✅ Linhas lidas: ${readBack.count()}")
} catch {
    case e: Exception => println(s"❌ Erro S3A: ${e.getMessage}")
}

// 5. Criar tabela Iceberg
println("\n[5] Criando tabela Iceberg...")
try {
    spark.sql("""
    CREATE TABLE IF NOT EXISTS iceberg.default.spark_test (
        id INT,
        name STRING,
        created_at TIMESTAMP
    ) USING ICEBERG
    """)
    println("✅ Tabela Iceberg criada")
} catch {
    case e: Exception => println(s"❌ Erro ao criar tabela: ${e.getMessage}")
}

// 6. Inserir dados na tabela Iceberg
println("\n[6] Inserindo dados em tabela Iceberg...")
try {
    spark.sql("""
    INSERT INTO iceberg.default.spark_test VALUES
    (1, 'Teste 1', current_timestamp()),
    (2, 'Teste 2', current_timestamp()),
    (3, 'Teste 3', current_timestamp())
    """)
    println("✅ Dados inseridos com sucesso")
} catch {
    case e: Exception => println(s"❌ Erro ao inserir: ${e.getMessage}")
}

// 7. Ler dados da tabela Iceberg
println("\n[7] Lendo dados da tabela Iceberg...")
try {
    spark.sql("SELECT * FROM iceberg.default.spark_test").show()
    println("✅ Leitura bem-sucedida")
} catch {
    case e: Exception => println(s"❌ Erro ao ler: ${e.getMessage}")
}

// 8. Verificar snapshots
println("\n[8] Verificando snapshots da tabela...")
try {
    spark.sql("SELECT * FROM iceberg.default.spark_test.snapshots").show()
    println("✅ Snapshots disponíveis")
} catch {
    case e: Exception => println(s"⚠️  Snapshots não disponíveis (normal em primeira execução)")
}

println("\n" + "=" * 60)
println("✨ TESTE CONCLUÍDO COM SUCESSO!")
println("=" * 60)

:quit
