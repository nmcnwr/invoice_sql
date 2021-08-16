
newline = '\n'
msisdn = 33
sql = ''
with open('sql/subs1001.sql', 'r') as file:

    for line in file:
        line = line.partition('--')[0]
        line = line.rstrip()
        sql += line + ' '
        sql = sql.format(**locals())

    print(sql)
    #
    # sql_query2 = sql_query1.format(**locals())
    # print(sql_query2)


