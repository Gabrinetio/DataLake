from pyhive import hive

conn = hive.connect(host="db-hive.gti.local", port=10000, auth="NOSASL", database="default")
cur = conn.cursor()
cur.execute("select 1")
print(cur.fetchone())
conn.close()
