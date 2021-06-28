WITH SETTING AS
    (
        select 59563601                                                as SUBS_ID
             , DATE '2019-06-05'                                       as TIME_START
             , TO_DATE('2020-06-25 11:40:00', 'YYYY-MM-DD HH24:MI:SS') as TIME_STOP
             , 1                                                       as VIEW_DATES_INVOICE
             , 1                                                       as VIEW_PAYMENT
             , '(\wаланс:?\s+.\d*.\d\d\s+руб\.)'                       as REGEXP_01
             , '(\wалансу\s-?\d*[.|,]\d+)'                             as REGEXP_02 -- к балансу -455,9
             , '(\wалансе\s\d*[.|,]\d\d)'                              as REGEXP_03 -- на балансе 341.90 руб.


        from DUAL
    )
   , DD as
    (
        SELECT TNAME, D_A_T_E, V_INVOICE
        FROM (
                 SELECT '0_DATE'                      TNAME
                      , (TIME_START + (LEVEL - 1)) AS D_A_T_E
                 FROM SETTING
                 CONNECT BY LEVEL <= (TIME_STOP - TIME_START)
             )
                 LEFT JOIN
             (
                 SELECT TRUNC(INSTALL_DATE)                                    INSTALL_DATE
                      , LISTAGG(VERSION, ', ') WITHIN GROUP (ORDER BY VERSION) V_INVOICE
                 FROM INV_VERSION
                 WHERE 0 = 0
                   AND INSTALL_DATE >= (select TIME_START from SETTING)
                   AND INSTALL_DATE <= (select TIME_STOP from SETTING)
                   AND NOT REGEXP_LIKE(VERSION, '[A-Za-z]')
                 GROUP BY TRUNC(INSTALL_DATE)
             ) ON D_A_T_E = INSTALL_DATE
    )

   , TT AS
    (
        SELECT '40_MESSAGE_SENDED'                                                           TNAME
             , T1.CRE_USER_ID || ' ' || T5.LOGIN                                             CRE_USER_ID
             , T1.START_DATE                                                                 CRE_DATE
             , T1.DELIVERED                                                                  END_DATE
             , T1.MSG_TYPE_ID || ' ' || T2.MSG_TYPE_NAME || ' ' || T1.PARAM1                 COMMENT_1
             , T1.TRPL_ID || ' ' || T3.TRPL_NAME || ' ' || T1.SERV_ID || ' ' || T4.SERV_NAME TRPL_SERV
             , T1.MESSAGE_TEXT                                                               COMMENT_2
        FROM MESSAGE_SENDED T1
                 LEFT JOIN MESSAGE_TYPE T2 ON T1.MSG_TYPE_ID = T2.MSG_TYPE_ID
                 LEFT JOIN TARIFF_PLAN T3 ON T1.TRPL_ID = T3.TRPL_ID
                 LEFT JOIN SERVICE T4 ON T1.SERV_ID = T4.SERV_ID
                 LEFT JOIN INV_USER T5 ON T1.CRE_USER_ID = T5.USER_ID
        WHERE 3 = 3
          AND T1.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND T1.START_DATE > (select TIME_START from SETTING)
          AND T1.START_DATE < (select TIME_STOP from SETTING)
    )

   , X101 AS
    (
        SELECT '10_SUBSCRIBER'             TNAME
             , ACTIVATION_DATE             CRE_DATE
             , ROUND(AVG_CHARGE, 2)        SUMM_$
             , 'FIRST_CALL ' || FIRST_CALL COMMENT_1
             , 'LAST_CALL ' || LAST_CALL   COMMENT_2
        FROM SUBSCRIBER
        WHERE 1 = 1
          AND SUBS_ID = (SELECT SUBS_ID FROM SETTING)
    )


   , X102 AS
    (
        SELECT '20_PAYMENT'                                          TNAME
             , M1.CRE_USER_ID || ' ' || T5.LOGIN                     CRE_USER_ID
             , M1.CRE_DATE
             , NVL(M1.DEL_DATE, M1.OB_EDATE)                         END_DATE
             , ROUND(M1.SUMM_$, 2)                                   SUMM_$
             , M1.PT_ID || ';' || M1.PAYDT_ID || ' ' || M2.PAYDT_DEF COMMENT_1
        FROM PAYMENT M1
                 LEFT JOIN PAYD_TYPE M2 ON M1.PAYDT_ID = M2.PAYDT_ID
                 LEFT JOIN INV_USER T5 ON M1.CRE_USER_ID = T5.USER_ID
        WHERE 1 = 1
          AND M1.CLNT_ID = (SELECT CLNT_ID FROM SUBS_LIST_VIEW WHERE SUBS_ID = (SELECT SUBS_ID FROM SETTING))
          AND M1.CRE_DATE > (select TIME_START from SETTING)
          AND M1.CRE_DATE < (select TIME_STOP from SETTING)
    )
   , X104 AS
    (
        SELECT '30_CHARGE'                                                                 TNAME
             , C.CRE_USER_ID || ' ' || T5.LOGIN                                            CRE_USER_ID
             , TP.TRPL_ID || ' ' || TP.TRPL_NAME || ' ' || S.SERV_ID || ' ' || S.SERV_NAME TRPL_SERV
             , CT.CHARGE_TYPE
             , C.CHARGE_DATE                                                               CRE_DATE
             , ROUND(C.SUMM_$, 2)                                                          CHARGE_VALUE
             , C.CRE_DATE                                                                  CRE_DATE_INI
             , C.START_CHRG_INTERVAL
             , C.END_CHRG_INTERVAL                                                         END_DATE
             , C.START_CHRG_INTERVAL || ' ' || C.END_CHRG_INTERVAL                         COMMENT_2
             , CT.CHARGE_TYPE || ' ' || C.CRE_DATE                                         COMMENT_1
        FROM CHARGE C
                 INNER JOIN CHARGE_TYPE CT ON CT.CHTYPE_ID = C.CHTYPE_ID
                 LEFT OUTER JOIN SERVICE S ON S.SERV_ID = C.SERV_ID
                 LEFT OUTER JOIN TARIFF_PLAN TP ON TP.TRPL_ID = C.TRPL_ID
                 LEFT JOIN INV_USER T5 ON C.CRE_USER_ID = T5.USER_ID
        WHERE 2 = 2
          AND C.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND C.CHARGE_DATE > (select TIME_START from SETTING)
          AND C.CHARGE_DATE < (select TIME_STOP from SETTING)
          AND C.CHTYPE_ID <> -2
    )
   , X105 AS
    (
        SELECT '55_SWCH_CHARGE'                    TNAME
             , C.CRE_USER_ID || ' ' || T5.LOGIN    CRE_USER_ID
             , TP.TRPL_ID || ' ' || TP.TRPL_NAME || ' ' || S.SERV_ID || ' ' || S.SERV_NAME || ' ' || D.SERV_ID || ' ' ||
               D.SERV_NAME                         TRPL_SERV
             , CT.CHARGE_TYPE
             , C.CHARGE_DATE
             , ROUND(C.SUMM_$, 2)                  CHARGE_VALUE
             , C.CRE_DATE
             , C.START_TIME_INTERVAL               ORDER_TIME
             , C.END_TIME_INTERVAL                 END_DATE
             , 'Заказ на списание ' || (CASE WHEN C.SUMM_$ = 0 THEN NULL ELSE C.SUMM_$ END) || C.START_TIME_INTERVAL ||
               ' - ' || C.END_TIME_INTERVAL        COMMENT_2
             , CT.CHARGE_TYPE || ' ' || C.CRE_DATE COMMENT_1
        FROM SWCH_CHARGE C
                 INNER JOIN CHARGE_TYPE CT ON CT.CHTYPE_ID = C.CHTYPE_ID
                 LEFT OUTER JOIN SERVICE S ON S.SERV_ID = C.SERV_ID
                 LEFT OUTER JOIN SERVICE D ON D.SERV_ID = C.SERV_DELAY_ID
                 LEFT OUTER JOIN TARIFF_PLAN TP ON TP.TRPL_ID = C.TRPL_ID
                 LEFT JOIN INV_USER T5 ON C.CRE_USER_ID = T5.USER_ID
        WHERE 2 = 2
          AND C.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND C.CHARGE_DATE > (select TIME_START from SETTING)
          AND C.CHARGE_DATE < (select TIME_STOP from SETTING)
          AND C.CHTYPE_ID <> -2
    )

   , X106 as
    (
        SELECT '50_SERV_ORDER'                                                                            TNAME
             , lpad(' ', 3 * level) || SERV_ID || ' ' || SERV_NAME || ', ' || SACT_ID || ' ' || SACT_NAME TRPL_SERV
             , PARENT_SORD_ID
             , SORD_ID
             , CSC_ID
             , CHARGE_ORDER
             , CRE_USER_ID
             , CRE_DATE
             , ORDER_TIME
        from (
                 SELECT D1.SERV_ID
                      , D2.SERV_NAME
                      , D1.SACT_ID
                      , D3.SACT_NAME
                      , D1.PARENT_SORD_ID
                      , D1.SORD_ID
                      , D1.CSC_ID
                      , D1.CHARGE_ORDER
                      , D1.CRE_USER_ID || ' ' || T5.LOGIN CRE_USER_ID
                      , D1.CRE_DATE
                      , D1.ORDER_TIME
                 FROM SERV_ORDER D1
                          INNER JOIN SERVICE D2 ON D1.SERV_ID = D2.SERV_ID
                          INNER JOIN SERV_ACTION D3 ON D1.SACT_ID = D3.SACT_ID
                          LEFT JOIN INV_USER T5 ON D1.CRE_USER_ID = T5.USER_ID
                 WHERE 1 = 1
                   AND SUBS_ID = (select SUBS_ID from SETTING)
                   AND ORDER_TIME > (select TIME_START from SETTING)
                   AND ORDER_TIME < (select TIME_STOP from SETTING)
             )
        START WITH PARENT_SORD_ID is null
        CONNECT BY PRIOR SORD_ID = PARENT_SORD_ID
    )

   , X107 as
    (
        select '60_SORD_BUFFER'                                  TNAME
             , SB.SERV_ID || ' ' || D2.SERV_NAME || ' ' || SB.PARAM1 || ', ' || SB.SACT_ID || ' ' ||
               D3.SACT_NAME                                      TRPL_SERV

             , SB.CRE_USER_ID || ' ' || T5.LOGIN                 CRE_USER_ID
             , SB.CRE_DATE
             , SB.TARGET_DATE                                    ORDER_TIME
             , 'CHARGE_ORDER=' || SB.CHARGE_ORDER
            || ', ' || 'SWITCHOFF_BASE_SERV=' || SB.SWITCHOFF_BASE_SERV
            || ', ' || 'CHECK_SWITCHON=' || SB.CHECK_SWITCHON
            || ', ' || 'CHECK_CHARGE=' || SB.CHECK_CHARGE        COMMENT_2

             , decode(SB.SORD_STAT_ID
                   , 0, '0 Отложен до активации абонента'
                   , -1, '-1 Создан по текущему заказу'
                   , -2, '-2 Создан по заказу на будущее'
                   , -3, '-3 Создан по заказу на будущее с подтвержд.'
                   ) || ', ' || SB.CSC_ID || ' ' || CCA.CSC_NAME COMMENT_1


        from SORD_BUFFER SB
                 INNER JOIN SERVICE D2 ON SB.SERV_ID = D2.SERV_ID
                 INNER JOIN SERV_ACTION D3 ON SB.SACT_ID = D3.SACT_ID
                 LEFT JOIN INV_USER T5 ON SB.CRE_USER_ID = T5.USER_ID
                 INNER JOIN COUSE_STATUS_CHANGE CCA ON SB.CSC_ID = CCA.CSC_ID

        WHERE 3 = 3
          AND SB.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND SB.CRE_DATE > (select TIME_START from SETTING)
          AND SB.CRE_DATE < (select TIME_STOP from SETTING)
    )

   , X108 as
    (
        select '70_SUBS_SERV_HISTORY'                                                          TNAME
             , D1.SERV_ID || ' ' || D1.SERV_NAME || ' ' || D2.SSTAT_ID || ' ' || D2.SSTAT_NAME TRPL_SERV
             , D3.CSC_ID || ' ' || D3.CSC_NAME                                                 COMMENT_1
             , D4.USER_ID || ' ' || D4.LOGIN                                                   CRE_USER_ID
             , STIME                                                                           ORDER_TIME
             , ETIME                                                                           END_DATE
             , CRE_DATE

             , decode(ACTIVATION_DATE, null, null, ACTIVATION_DATE,
                      'AD=' || TO_CHAR(ACTIVATION_DATE, 'YYYY.MM.DD HH24:MI') || '; ', ACTIVATION_DATE)
            || decode(LAST_ACTIVATION_DATE, null, null, LAST_ACTIVATION_DATE,
                      'LAD=' || TO_CHAR(LAST_ACTIVATION_DATE, 'YYYY.MM.DD HH24:MI') || '; ', LAST_ACTIVATION_DATE)
            || decode(LAST_CONNECTION_DATE, null, null, LAST_CONNECTION_DATE,
                      'LCD=' || TO_CHAR(LAST_CONNECTION_DATE, 'YYYY.MM.DD HH24:MI') || '; ', LAST_CONNECTION_DATE)
                                                                                               COMMENT_2

        from subs_serv_history T1
                 INNER JOIN SERVICE D1 ON D1.SERV_ID = T1.SERV_ID
                 INNER JOIN SERV_STATUS D2 ON D2.SSTAT_ID = T1.SSTAT_ID
                 INNER JOIN COUSE_STATUS_CHANGE D3 ON D3.CSC_ID = T1.CSC_ID
                 INNER JOIN INV_USER D4 ON D4.USER_ID = T1.CRE_USER_ID


        WHERE 3 = 3
          AND T1.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND T1.CRE_DATE > (select TIME_START from SETTING)
          AND T1.CRE_DATE < (select TIME_STOP from SETTING)
    )
   , X109 as
    (
        select '75_SUBS_HISTORY'                                                                               TNAME
             , CLNT_ID ||
               decode(DEF_PAY_PACK_CLNT, null, null, DEF_PAY_PACK_CLNT, ' Pay by: ' || DEF_PAY_PACK_CLNT)      CLNT_ID
             --, DD.ST_ID || ' ' || D4.SUBS_TYPE                                                            ST_ID
             , DD.STAT_ID || ' ' || D3.STATUS                                                                  STAT_ID
             , DD.TRPL_ID || ' ' || D6.TRPL_NAME                                                               TRPL_SERV
             , STIME                                                                                           ORDER_TIME
             , ETIME                                                                                           END_DATE
             , DD.CRE_USER_ID || ' ' || D2.LOGIN                                                               CRE_USER_ID
             , DD.CRE_DATE
             , DECODE(DD.CSC_ID, null, null, BLOCK_QUOTA, 'CSC_ID=' || DD.CSC_ID || ' ' || D5.CSC_NAME || ';') COMMENT_1
             , DECODE(DD.TAL_ID, null, null, DD.TAL_ID, 'TAL_ID=' || DD.TAL_ID || ' ' || D1.TAL_NAME || ';')
            || DECODE(BLOCK_QUOTA, null, null, BLOCK_QUOTA, 'BLOCK_QUOTA=' || BLOCK_QUOTA || ';')
            || DECODE(CHANGE_TRPL, null, null, 0, 'CHANGE_TRPL=0(не учитывать смену ТП);', CHANGE_TRPL,
                      'CHANGE_TRPL=' || CHANGE_TRPL || ';')
            || DECODE(PHONE_ID, null, null, PHONE_ID, 'PHONE.PHONE_ID=' || PHONE_ID || ';')
            || DECODE(SORD_ID, null, null, SORD_ID, 'SERV_ORDER.SORD_ID=' || SORD_ID || ';')                   COMMENT_2


        from SUBS_HISTORY DD
                 LEFT JOIN TAR_ALLOW_LEVEL D1 on D1.TAL_ID = DD.TAL_ID
                 INNER JOIN INV_USER D2 ON D2.USER_ID = DD.CRE_USER_ID
                 LEFT JOIN STATUS D3 on D3.STAT_ID = DD.STAT_ID
                 INNER JOIN SUBS_TYPE D4 on D4.ST_ID = DD.ST_ID
                 LEFT JOIN COUSE_STATUS_CHANGE D5 ON D5.CSC_ID = DD.CSC_ID
                 LEFT JOIN TARIFF_PLAN D6 ON D6.TRPL_ID = DD.TRPL_ID
        WHERE 3 = 3
          AND DD.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND DD.CRE_DATE > (select TIME_START from SETTING)
          AND DD.CRE_DATE < (select TIME_STOP from SETTING)
    )


SELECT V_INVOICE
     , X109.CLNT_ID
     , COALESCE(TT.TNAME, X101.TNAME, X102.TNAME, X104.TNAME, X105.TNAME, X106.TNAME, X107.TNAME, X108.TNAME,
                X109.TNAME)                                                                                TNAME
     , COALESCE(TT.CRE_USER_ID, X102.CRE_USER_ID, X104.CRE_USER_ID, X106.CRE_USER_ID, X105.CRE_USER_ID,
                X107.CRE_USER_ID, X108.CRE_USER_ID, X109.CRE_USER_ID)                                      CRE_USER_ID
     , COALESCE(DD.D_A_T_E, TT.CRE_DATE, X102.CRE_DATE, X104.CRE_DATE, X106.CRE_DATE, X101.CRE_DATE, X105.CRE_DATE,
                X107.CRE_DATE, X108.CRE_DATE, X109.CRE_DATE)                                               CRE_DATE
     , COALESCE(X106.ORDER_TIME, X105.ORDER_TIME, X107.ORDER_TIME, X108.ORDER_TIME, X109.ORDER_TIME, null) ORDER_TIME
     , COALESCE(TT.END_DATE, X102.END_DATE, X104.END_DATE, X105.END_DATE, X108.END_DATE, X109.END_DATE)    END_DATE
     , COALESCE(X102.SUMM_$, X101.SUMM_$)                                                                  PAY_$
     , DECODE(X104.CHARGE_VALUE, 0, null, X104.CHARGE_VALUE)                                               CHARGE_$
     , REGEXP_REPLACE(
        REGEXP_REPLACE(
                coalesce(
                        REGEXP_SUBSTR(tt.COMMENT_2, (select REGEXP_01 from SETTING)),
                        REGEXP_SUBSTR(tt.COMMENT_1, (select REGEXP_02 from SETTING)),
                        REGEXP_SUBSTR(tt.COMMENT_2, (select REGEXP_03 from SETTING)))
            , ':|\s|\.$|[[:alpha:]]', '')
    , ',', '.')                                                                                            BALANCE_$
     , COALESCE(TT.TRPL_SERV, X104.TRPL_SERV, X105.TRPL_SERV, X106.TRPL_SERV, X107.TRPL_SERV, X108.TRPL_SERV,
                X109.TRPL_SERV)                                                                            TRPL_SERV
     , COALESCE(TT.COMMENT_1, X102.COMMENT_1, X104.COMMENT_1, X101.COMMENT_1,
                X105.COMMENT_1, X107.COMMENT_1, X108.COMMENT_1, X109.COMMENT_1)                            COMMENTS_1
     , COALESCE(TT.COMMENT_2, X104.COMMENT_2, X101.COMMENT_2, X105.COMMENT_2, X107.COMMENT_2, X108.COMMENT_2,
                X109.COMMENT_2)                                                                            COMMENTS_2

FROM TT
         FULL OUTER JOIN DD ON TT.TNAME = DD.TNAME
         FULL OUTER JOIN X101 ON TT.TNAME = X101.TNAME
         FULL OUTER JOIN X102 ON TT.TNAME = X102.TNAME
         FULL OUTER JOIN X104 ON TT.TNAME = X104.TNAME
         FULL OUTER JOIN X105 ON TT.TNAME = X105.TNAME
         FULL OUTER JOIN X106 ON TT.TNAME = X106.TNAME
         FULL OUTER JOIN X107 ON TT.TNAME = X107.TNAME
         FULL OUTER JOIN X108 ON TT.TNAME = X108.TNAME
         FULL OUTER JOIN X109 ON TT.TNAME = X109.TNAME

ORDER BY COALESCE(DD.D_A_T_E, TT.CRE_DATE, X101.CRE_DATE, X102.CRE_DATE, X104.CRE_DATE
    , X105.CRE_DATE, X106.CRE_DATE, X107.CRE_DATE, X108.CRE_DATE, X109.CRE_DATE)
       , TNAME
       , COALESCE(X102.SUMM_$, X104.CHARGE_VALUE) desc
;