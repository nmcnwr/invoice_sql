from fastapi import FastAPI, Request, Depends, BackgroundTasks
from fastapi.templating import Jinja2Templates
from typing import Optional
from pydantic import BaseModel
from sqlalchemy.engine import create_engine
import pandas as pd
import numpy as np
from fastapi.staticfiles import StaticFiles
import re

# connstr1 = 'SMASTER/SMASTER@192.168.17.91:1521/i459s5'

DIALECT = 'oracle'
SQL_DRIVER = 'cx_oracle'
USERNAME = 'SMASTER'
PASSWORD = 'SMASTER'
HOST = '10.246.16.203'
PORT = 1521
# SERVICE = 'i460s10'
# ENGINE_PATH_WIN_AUTH = DIALECT + '+' + SQL_DRIVER + '://' + USERNAME \
#                        + ':' + PASSWORD + '@' + HOST \
#                        + ':' + str(PORT) + '/?service_name=' + SERVICE
#
# engine = create_engine(ENGINE_PATH_WIN_AUTH)

app = FastAPI()

templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def msisdn_form(request: Request):
    return templates.TemplateResponse(
        "msisdn_form.html",
        {"request": request})


@app.get("/msisdn_print/")
async def get_msisdn(request: Request, msisdn: int, db: str):

    list_192_168_17_91 = ['i459s5']
    list_10_246_16_203 = ['i460s10', 'i460s1']
    if db in list_192_168_17_91:
        HOST = '192.168.17.91'
    if db in list_10_246_16_203:
        HOST = '10.246.16.203'


    ENGINE_PATH_WIN_AUTH = DIALECT + '+' + SQL_DRIVER + '://' + USERNAME \
                           + ':' + PASSWORD + '@' + HOST \
                           + ':' + str(PORT) + '/?service_name=' + db

    engine = create_engine(ENGINE_PATH_WIN_AUTH)

    content = '%s %s %s' % (request.method, request.url.path, request.client.host)
    # print(f'db={db}')

    # .format(**locals() меняет все локальные шаблоны на переменные msisdn=msisdn
    # sql_query = f"""select * from subs_list_view where msisdn='{msisdn}'"""

    newline = '\n'  # Avoids SyntaxError: f-string expr cannot include a backslash
    sql = ''
    with open('sql/subs1002.sql', 'r') as file:
        # sql_query2 = f"{file.read().replace(newline, ' ')}".format(**locals())
        for line in file:
            line = line.partition('--')[0]
            line = line.rstrip()
            sql += line + ' '
            sql_query2 = sql.format(**locals())

    df111 = pd.read_sql_query(sql_query2, engine)
    df111 = df111.replace(np.nan, '', regex=True)

    df111 = df111.replace(to_replace='(.*)((?i)блокирова)(.*)', value='<font color="red">'+r"\1\2\3"+'</font>', regex=True)
    df111 = df111.replace(to_replace='(.*)((?i)active)(.*)', value='<font color="green">'+r"\1\2\3"+'</font>', regex=True)
    df111.trpl_serv.replace(r'(.*)(Включить|Активна)(.*)', '<font color="green">'+r"\1\2\3"+'</font>', inplace=True, regex=True)
    df111.tname.replace(r'\_', ' ', inplace=True, regex=True)


    headings = list(df111.columns.values)
    data = list(df111.itertuples(index=False))

    return templates.TemplateResponse("msisdn_print.html",
                                      {"request": request,
                                       "msisdn": msisdn,
                                       "db": db,
                                       "headings": headings,
                                       "data": data
                                       })
# DONE: SQL вынести в отдельную папку и файл(ы)
# TODO: подключить sqlalchemy + basemodel
# DONE: head + foot
# DONE: большой селект
# TODO: remove comments from SQL test_reading
# TODO: open sql in new window
# TODO: sql - add TRPL_ID before trpl_ID
# TODO: sql - add SERV_ID before serv_id
# TODO: open TRPL route from trpl_id link
# TODO: open SERVICE route from serv_id link
# TODO: sql - check ORDER time
# TODO: sql - check DBs list
# TODO: sql - select DBs list to Jinja2 template


