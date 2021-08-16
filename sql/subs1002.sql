WITH SETTING AS
    (
        select



             (select subs_id from subs_list_view where msisdn in ({msisdn}))        as SUBS_ID
             , DATE '2021-08-01'                                       as TIME_START
             , TO_DATE('2021-08-28 11:40:00', 'YYYY-MM-DD HH24:MI:SS') as TIME_STOP
             , '2561,3281'                                             as SCENARIO_ID
             , '13295'                                                 as TRPL_ID


             , 'USE_SYSDATE,DATE_CONNECT_PRICE,COMPENSATED_OPERATION_ALLOWED_CT_ID_LIST,COMPENSATED_OPERATION_ALLOWED_PM_ID_LIST,COMPENSATED_PAYD_TYPE_ID_LIST,COMPENSATED_CHARGE_TYPE_ID_LIST,PF_BALANCE_ACCESS_EXCLUDE'
                                                                       as INV_PARAMETERS


             , 1                                                       as VIEW_DATES_INVOICE
             , 1                                                       as VIEW_PAYMENT
             , '(\wаланс:?\s+.\d*.\d\d\s+руб\.)'                       as REGEXP_01
             , '(\wалансу\s-?\d*[.|,]\d+)'                             as REGEXP_02
             , '(\wалансе\s\d*[.|,]\d\d)'                              as REGEXP_03


        from DUAL
    )


   , DD as
    (
        SELECT TNAME, D_A_T_E, V_INVOICE
        FROM (
                 SELECT

                      decode(trunc(sysdate),(TIME_START + (LEVEL - 1)), '01_SYSDATE' , '02_DATE' ) AS TNAME
                      , decode(trunc(sysdate),(TIME_START + (LEVEL - 1)), SYSDATE, (TIME_START + (LEVEL - 1))) AS D_A_T_E
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

  , X240 AS
    (

       SELECT T4.PF_ID,T5.PF_NAME, T1.SCENARIO_ID, T4.SCENARIO_NAME, T1.BRANCH_ID,T6.BRANCH_NAME,T1.TRPL_ID, T2.TRPL_NAME,  T1.SERV_ID , T3.SERV_NAME
        FROM PRODUCT_SCENARIO_RESTRICTION T1, TARIFF_PLAN T2, SERVICE T3 , PRODUCT_SCENARIO T4 , PRODUCT_FAMILY T5, BRANCH T6
        WHERE
              200=200
              AND T1.TRPL_ID=T2.TRPL_ID
              AND T1.SERV_ID=T3.SERV_ID
              AND T1.SCENARIO_ID=T4.SCENARIO_ID
              AND T1.BRANCH_ID=T6.BRANCH_ID
              AND T4.PF_ID=T5.PF_ID
              AND T4.PF_ID=5
              and T1.TRPL_ID              IN
                (
                SELECT TRIM(REGEXP_SUBSTR((SELECT TRPL_ID FROM SETTING),'[^,]+',1,LEVEL)) PARAM_NAME
                FROM SETTING
                CONNECT BY LEVEL <= REGEXP_COUNT((SELECT TRPL_ID FROM SETTING), '\s*,\s*')+1
                )
    )

   , X200 AS
    (


        select
             '05_PRODUCT_SCENARIO_PARAM_VALUE' as TNAME
             , T1.PARAM_NAME||'='|| T1.PARAM_VALUE||
               case when nvl(T2.CRE_DATE,T1.ETIME) > sysdate then ' Active' END  TRPL_SERV
             , case when T1.STIME>T1.CRE_DATE then T1.STIME else T1.CRE_DATE end  CRE_DATE
             , nvl(T2.CRE_DATE,T1.ETIME)                                          END_DATE
             , T1.CRE_USER_ID||' '||D1.LOGIN                                      CRE_USER_ID
             , 'SCENARIO_ID=' || T1.SCENARIO_ID ||' '|| X240.SCENARIO_NAME        COMMENT_1
             , D2.PARAM_DESC                                                      COMMENT_2
        from PRODUCT_SCENARIO_PARAM_VALUE T1
        full outer join PRODUCT_SCENARIO_PARAM_VALUE T2
        on T1.NUM_HISTORY=T2.NUM_HISTORY-1 and T1.PSPV_ID=T2.PSPV_ID and T1.scenario_id=T2.scenario_id
        LEFT JOIN INV_USER D1 ON D1.USER_ID = T1.CRE_USER_ID
        LEFT JOIN PRODUCT_PARAM_DICT D2 on T1.PARAM_NAME=D2.PARAM_NAME
        left join X240 on T1.SCENARIO_ID=X240.SCENARIO_ID
        where
             1=1
             and T1.SCENARIO_ID     IN
            (
                SELECT TRIM(REGEXP_SUBSTR((SELECT SCENARIO_ID FROM SETTING),'[^,]+',1,LEVEL)) PARAM_NAME
                FROM SETTING
                CONNECT BY LEVEL <= REGEXP_COUNT((SELECT SCENARIO_ID FROM SETTING), '\s*,\s*')+1
            )

        group by
              T1.PARAM_NAME, T1.PARAM_VALUE ,T1.STIME, T1.ETIME, T1.CRE_DATE, T2.CRE_DATE, T1.SCENARIO_ID
              , X240.SCENARIO_NAME, D2.PARAM_DESC, T1.CRE_USER_ID, D1.LOGIN

    )
  , X222 AS
    (


        select
          '03_SUBS_LIST_VIEW'                                                     as TNAME
          , sysdate                                                               as ORDER_TIME
          , DATE '1969-01-01'                                                     as CRE_DATE
          , MSISDN||' '||STATUS                                                   COMMENT_1
          ,'BRANCH_ID='||BRANCH_ID||'; USI_ID='||USI_ID||'; USI='||USI||'; SWITCH_ID='||SWITCH_ID||'; ACCOUNT='||ACCOUNT COMMENT_2
          , V1.trpl_id||' '||T1.TRPL_NAME                                         TRPL_SERV
          , to_char(CLNT_ID)                                                      CLNT_ID
        from SUBS_LIST_VIEW V1
        left join tariff_plan T1 on T1.trpl_id=V1.trpl_id
        WHERE 1 = 1
          AND SUBS_ID = (SELECT SUBS_ID FROM SETTING)


    )
  , X225 AS
    (

        SELECT
            '04_CLIENT_BALANCE'                                                                     TNAME
            , to_char(CLNT_ID)                                                                      CLNT_ID
            , to_char(BALANCE_$)                                                                    BALANCE_$
            , BALANCE_ID||' ' ||CLNT_BAL_DESC                                                       TRPL_SERV
            , 'CLNT_BAL_ID='||CLNT_BAL_ID                                                           COMMENT_1
            , DECODE(INC_DATE, NULL, NULL, 'INC_DATE: ' ||TO_CHAR(INC_DATE, 'YYYY.MM.DD HH24:MI'))
            ||DECODE(DEC_DATE, NULL, NULL, ' DEC_DATE: ' ||TO_CHAR(DEC_DATE, 'YYYY.MM.DD HH24:MI')) COMMENT_2
            , CRE_DATE                                                                              CRE_DATE
            , DEL_DATE                                                                              END_DATE
        FROM CLIENT_BALANCE
        WHERE CLNT_ID = (SELECT CLNT_ID FROM SUBS_LIST_VIEW WHERE SUBS_ID=(SELECT SUBS_ID FROM SETTING))


    )
  , X230 AS
    (

        SELECT
            '06_INV_PARAMETER'                                                                     TNAME
            , DATE '1969-01-01'                                                                    CRE_DATE
            , T1.PRMT_NAME
            || DECODE(T1.VALUE_NUMBER, NULL, NULL, T1.VALUE_NUMBER, '='||T1.VALUE_NUMBER||' (VALUE_NUMBER)')
            || DECODE(T1.VALUE_STRING, NULL, NULL, T1.VALUE_STRING, '='||T1.VALUE_STRING||' (VALUE_STRING)') TRPL_SERV
            , T1.APPL_ID||' '||T2.DEF                                                              COMMENT_1
            , T1.COMMENTS                                                                          COMMENT_2

        FROM INV_PARAMETER T1, INV_APPLICATION T2
        WHERE PRMT_NAME IN
            (
            SELECT TRIM(REGEXP_SUBSTR((SELECT INV_PARAMETERS FROM SETTING),'[^,]+',1,LEVEL)) PARAM_NAME
            FROM SETTING
            CONNECT BY LEVEL <= REGEXP_COUNT((SELECT INV_PARAMETERS FROM SETTING), '\s*,\s*')+1
            )
            AND T1.APPL_ID=T2.APPL_ID


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
             , decode(C.START_CHRG_INTERVAL, null, null, 'START_CHRG_INTERVAL: ' ||TO_CHAR(C.START_CHRG_INTERVAL, 'YYYY.MM.DD HH24:MI') || ' до ' || TO_CHAR(C.END_CHRG_INTERVAL, 'YYYY.MM.DD HH24:MI'))COMMENT_2
             , CT.CHARGE_TYPE || ' ' || TO_CHAR(C.CRE_DATE, 'YYYY.MM.DD HH24:MI')          COMMENT_1
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
             , nvl(C.START_TIME_INTERVAL, C.DATE_CHARGE_NEXT)               ORDER_TIME
             , C.END_TIME_INTERVAL                 END_DATE
             , CT.CHARGE_TYPE ||' SUMM_$= ' || SUMM_$ || C.START_TIME_INTERVAL ||' - ' || C.END_TIME_INTERVAL        COMMENT_1
             , decode(SORDB_ID, null, null, SORDB_ID,'SORD_BUFFER.SORDB_ID='||SORDB_ID) COMMENT_2
        FROM SWCH_CHARGE C
                 LEFT JOIN CHARGE_TYPE CT ON CT.CHTYPE_ID = C.CHTYPE_ID
                 LEFT OUTER JOIN SERVICE S ON S.SERV_ID = C.SERV_ID
                 LEFT OUTER JOIN SERVICE D ON D.SERV_ID = C.SERV_DELAY_ID
                 LEFT OUTER JOIN TARIFF_PLAN TP ON TP.TRPL_ID = C.TRPL_ID
                 LEFT JOIN INV_USER T5 ON C.CRE_USER_ID = T5.USER_ID
        WHERE 2 = 2
          AND C.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND C.CRE_DATE > (select TIME_START from SETTING)
          AND C.CRE_DATE < (select TIME_STOP from SETTING)
          AND C.CHTYPE_ID <> -2
    )

   , X106 as
    (
        SELECT '50_SERV_ORDER'                                                                            TNAME
             , lpad(' ', 3 * level) || SERV_ID || ' ' || SERV_NAME || ', ' || SACT_ID || ' ' || SACT_NAME TRPL_SERV
             , PARENT_SORD_ID
             , SORD_ID
             , COMMENT_1
             , COMMENT_2
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
                      , D1.CSC_ID|| ' ' || D4.CSC_NAME COMMENT_1
                      , D1.CHARGE_ORDER
                      , D1.CRE_USER_ID || ' ' || T5.LOGIN CRE_USER_ID
                      , D1.CRE_DATE
                      , D1.ORDER_TIME

                      , decode(D1.SORDP_ID, null,null,D1.SORDP_ID,'SERV_ORDER_PARAM.SORDP_ID='||D1.SORDP_ID||'; ')
                       || decode(D1.DATE_CONNECT_PRICE, null,null,D1.DATE_CONNECT_PRICE,'DATE_CONNECT_PRICE='||TO_CHAR(D1.DATE_CONNECT_PRICE, 'YYYY.MM.DD HH24:MI')||'; ' )
                       || decode(D1.SB_ORDER_DATE, null,null,D1.SB_ORDER_DATE,'SB_ORDER_DATE='||TO_CHAR(D1.SB_ORDER_DATE, 'YYYY.MM.DD HH24:MI')||'; ')
                        COMMENT_2
                 FROM SERV_ORDER D1
                          INNER JOIN SERVICE D2 ON D1.SERV_ID = D2.SERV_ID
                          INNER JOIN SERV_ACTION D3 ON D1.SACT_ID = D3.SACT_ID
                          LEFT JOIN INV_USER T5 ON D1.CRE_USER_ID = T5.USER_ID
                          INNER JOIN COUSE_STATUS_CHANGE D4 ON D1.CSC_ID = D4.CSC_ID
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
             , 'SERV_ORDER_PARAM.SORDP_ID=' || SB.SORDP_ID
            || ', ' || 'CHARGE_ORDER=' || SB.CHARGE_ORDER
            || ', ' || 'SWITCHOFF_BASE_SERV=' || SB.SWITCHOFF_BASE_SERV
            || ', ' || 'CHECK_SWITCHON=' || SB.CHECK_SWITCHON
            || ', ' || 'CHECK_CHARGE=' || SB.CHECK_CHARGE        COMMENT_2

             , decode(SB.SORD_STAT_ID
                   , 0, 'SORD_STAT_ID=0 Отложен до активации абонента'
                   , -1, 'SORD_STAT_ID=-1 Создан по текущему заказу'
                   , -2, 'SORD_STAT_ID=-2 Создан по заказу на будущее'
                   , -3, 'SORD_STAT_ID=-3 Создан по заказу на будущее с подтвержд.'
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
                 LEFT JOIN SERVICE D1 ON D1.SERV_ID = T1.SERV_ID
                 LEFT JOIN SERV_STATUS D2 ON D2.SSTAT_ID = T1.SSTAT_ID
                 LEFT JOIN COUSE_STATUS_CHANGE D3 ON D3.CSC_ID = T1.CSC_ID
                 LEFT JOIN INV_USER D4 ON D4.USER_ID = T1.CRE_USER_ID


        WHERE 3 = 3
          AND T1.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND T1.CRE_DATE > (select TIME_START from SETTING)
          AND T1.CRE_DATE < (select TIME_STOP from SETTING)
    )
   , X109 as
    (
        select '65_SUBS_HISTORY'                                                                               TNAME
             ,decode(DEF_PAY_PACK_CLNT, null, to_char(CLNT_ID),CLNT_ID, to_char(CLNT_ID), 'DEF_PAY_PACK_CLNT='||DEF_PAY_PACK_CLNT||'; '|| CLNT_ID) CLNT_ID
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
                 LEFT JOIN INV_USER D2 ON D2.USER_ID = DD.CRE_USER_ID
                 LEFT JOIN STATUS D3 on D3.STAT_ID = DD.STAT_ID
                 LEFT JOIN SUBS_TYPE D4 on D4.ST_ID = DD.ST_ID
                 LEFT JOIN COUSE_STATUS_CHANGE D5 ON D5.CSC_ID = DD.CSC_ID
                 LEFT JOIN TARIFF_PLAN D6 ON D6.TRPL_ID = DD.TRPL_ID
        WHERE 3 = 3
          AND DD.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND DD.CRE_DATE > (select TIME_START from SETTING)
          AND DD.CRE_DATE < (select TIME_STOP from SETTING)
    )

, X110 as
    (

        select
            '45_CRED_CONTROL_LIST'                                                                               TNAME
            ,decode(DD.PARENT_CLNT_ID, DD.CLNT_ID, to_char(DD.CLNT_ID), 'PARENT_CLNT_ID='||DD.PARENT_CLNT_ID||', '|| DD.CLNT_ID) CLNT_ID
            ,DD.CONTROL_DATE           END_DATE
            ,DD.CRE_DATE
            ,DD.CRE_USER_ID||' '||D4.LOGIN CRE_USER_ID
            ,DD.SERV_ID||' '||D1.SERV_NAME TRPL_SERV
            ,'CCACT_ID='||DD.CCACT_ID||' '||D3.DESCRIPTION COMMENT_1
            ,'USE_CASCADE_BALANCE='||DD.USE_CASCADE_BALANCE||'; CPT_ID='||DD.CPT_ID||' '||D2.PAY_TYPE COMMENT_2



        from smaster.CRED_CONTROL_LIST DD
                 LEFT JOIN SERVICE D1 ON D1.SERV_ID = DD.SERV_ID
                 LEFT JOIN CLIENT_PAY_TYPE D2 ON D2.CPT_ID = DD.CPT_ID
                 LEFT JOIN smaster.CRED_CONTROL_ACTION D3 ON D3.CCACT_ID = DD.CCACT_ID
                 LEFT JOIN INV_USER D4 ON D4.USER_ID = DD.CRE_USER_ID

        WHERE 3 = 3
          AND DD.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
          AND DD.CRE_DATE > (select TIME_START from SETTING)
          AND DD.CRE_DATE < (select TIME_STOP from SETTING)
    )

, X111 as
    (


        select
            '52_SERV_ORDER_PARAM'                                                 TNAME
            , D1.CRE_USER_ID || ' ' || T5.LOGIN                                   CRE_USER_ID
            , D1.CRE_DATE
            , D1.ORDER_TIME
            , PARAM_NAME ||'='|| PARAM_VALUE||';'                                  COMMENT_1
            , D1.SERV_ID||' '||D2.SERV_NAME||', '|| D1.SACT_ID||' '|| D3.SACT_NAME
              ||', '|| D1.SORD_STAT_ID||' '|| D4.SORD_STAT_NAME                    TRPL_SERV
            , 'SORD_ID='||D1.SORD_ID||'; '||'SORDP_ID='||D1.SORDP_ID               COMMENT_2


        FROM SERV_ORDER D1
            INNER JOIN SERV_ORDER_PARAM T2 on D1.SORDP_ID=T2.SORDP_ID
            INNER JOIN SERVICE D2 ON D1.SERV_ID = D2.SERV_ID
            INNER JOIN SERV_ACTION D3 ON D1.SACT_ID = D3.SACT_ID
            LEFT JOIN INV_USER T5 ON D1.CRE_USER_ID = T5.USER_ID
            LEFT JOIN ORDER_STATUS D4 ON D1.SORD_STAT_ID = D4.SORD_STAT_ID
        where
            1=1
            AND D1.CRE_DATE > (select TIME_START from SETTING)
            AND D1.CRE_DATE < (select TIME_STOP from SETTING)
            and PARAM_NAME not like 'SYNC%'
            and PARAM_NAME not like 'OFFER%'
            and PARAM_NAME not like '%_WV'
            and PARAM_NAME not like '%_WD'
            and PARAM_VALUE is not null
            and D1.SORD_ID in (SELECT  SORD_ID FROM  SERV_ORDER WHERE SERV_ID=-20  AND SUBS_ID = (SELECT SUBS_ID FROM SETTING))
            and T2.SORDP_ID in (SELECT SORDP_ID FROM  SERV_ORDER WHERE SERV_ID=-20  AND SUBS_ID = (SELECT SUBS_ID FROM SETTING))

)

, X112 as
(

        SELECT
              '80_SUBS_SERV_CHARGE_PARAM'                                                           TNAME
              , DD.SERV_ID ||' '|| T1.SERV_NAME                                                     TRPL_SERV
              , DD.START_CHRG_INTERVAL                                                              CRE_DATE
              , DD.START_CHRG_INTERVAL                                                              ORDER_TIME
              , DD.END_CHRG_INTERVAL                                                                END_DATE
              , 'DATE_NEXT_CHARGE=' || TO_CHAR(DD.DATE_NEXT_CHARGE, 'YYYY.MM.DD HH24:MI')           COMMENT_1
              , 'CHARGE_QUANTITY=' || DD.CHARGE_QUANTITY                                            COMMENT_2

        FROM SUBS_SERV_CHARGE_PARAM DD
        LEFT JOIN SERVICE T1 ON T1.SERV_ID = DD.SERV_ID

        WHERE 3 = 3
              AND DD.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
              AND DD.START_CHRG_INTERVAL > (select TIME_START from SETTING)
              AND DD.END_CHRG_INTERVAL < (select TIME_STOP from SETTING)


)


, X113 as
    (

     select
            '61_SERV_ORDER_PARAM'                                                 TNAME
            , D1.CRE_USER_ID || ' ' || T5.LOGIN                                   CRE_USER_ID
            , D1.CRE_DATE
            , D1.TARGET_DATE                                                      ORDER_TIME
            , D1.SERV_ID||' '||D2.SERV_NAME||', '|| D1.SACT_ID||' '|| D3.SACT_NAME
              ||', TARGET_DATE='||TO_CHAR(D1.TARGET_DATE, 'YYYY.MM.DD HH24:MI')   TRPL_SERV
            , PARAM_NAME ||'='|| PARAM_VALUE||';'                                  COMMENT_1
            , 'SORD_BUFFER.SORDB_ID='||D1.SORDB_ID||'; '||'SORDP_ID='||D1.SORDP_ID COMMENT_2


        FROM SORD_BUFFER D1
            INNER JOIN SERV_ORDER_PARAM T2 on D1.SORDP_ID=T2.SORDP_ID
            INNER JOIN SERVICE D2 ON D1.SERV_ID = D2.SERV_ID
            INNER JOIN SERV_ACTION D3 ON D1.SACT_ID = D3.SACT_ID
            LEFT JOIN INV_USER T5 ON D1.CRE_USER_ID = T5.USER_ID
        where
            1=1
            AND D1.CRE_DATE > (select TIME_START from SETTING)
            AND D1.CRE_DATE < (select TIME_STOP from SETTING)
            and PARAM_VALUE is not null
            and T2.SORDP_ID in
            (
                      SELECT   SORDP_ID FROM  SORD_BUFFER
                         WHERE SERV_ID=-20
                           AND SUBS_ID = (SELECT SUBS_ID FROM SETTING)

            )

)

, X114 as
    (
        SELECT
              '85_SUBS_SERV_CHARGE'                                                                  TNAME
              , DD.SERV_ID ||' '|| T1.SERV_NAME                                                     TRPL_SERV
              , DD.START_CHRG_INTERVAL                                                              CRE_DATE
              , DD.START_CHRG_INTERVAL                                                              ORDER_TIME
              , DD.END_CHRG_INTERVAL                                                                END_DATE
              , 'Оплаченные периоды спящих пакетов LAST_CHRG_DATE='
              || TO_CHAR(DD.LAST_CHRG_DATE, 'YYYY.MM.DD HH24:MI')                                   COMMENT_1
              , 'количество распаковок спящих пакетов CHARGE_QUANTITY=' || DD.CHARGE_QUANTITY       COMMENT_2

        FROM SUBS_SERV_CHARGE DD
        LEFT JOIN SERVICE T1 ON T1.SERV_ID = DD.SERV_ID

        WHERE 3 = 3
              AND DD.SUBS_ID = (SELECT SUBS_ID FROM SETTING)
              AND DD.START_CHRG_INTERVAL > (select TIME_START from SETTING)
              AND DD.END_CHRG_INTERVAL < (select TIME_STOP from SETTING)

)


SELECT V_INVOICE

     , COALESCE(DD.TNAME, TT.TNAME, X101.TNAME, X102.TNAME, X104.TNAME, X105.TNAME, X106.TNAME, X107.TNAME, X108.TNAME
                , X109.TNAME, X110.TNAME, X111.TNAME, X112.TNAME, X113.TNAME, X114.TNAME
                , X200.TNAME, X222.TNAME, X225.TNAME, X230.TNAME)
                                                                                                                       TNAME

     , COALESCE(X109.CLNT_ID, X110.CLNT_ID, X222.CLNT_ID, X225.CLNT_ID)
                                                                                                                       CLNT_ID
     , COALESCE(TT.CRE_USER_ID, X102.CRE_USER_ID, X104.CRE_USER_ID, X106.CRE_USER_ID, X105.CRE_USER_ID
                , X107.CRE_USER_ID, X108.CRE_USER_ID, X109.CRE_USER_ID, X110.CRE_USER_ID, X111.CRE_USER_ID
                , X113.CRE_USER_ID, X200.CRE_USER_ID)
                                                                                                                       CRE_USER_ID
     , COALESCE(DD.D_A_T_E, TT.CRE_DATE, X102.CRE_DATE, X104.CRE_DATE, X106.CRE_DATE, X101.CRE_DATE, X105.CRE_DATE,
                X107.CRE_DATE, X108.CRE_DATE, X109.CRE_DATE, X110.CRE_DATE, X111.CRE_DATE
                , X113.CRE_DATE, X114.CRE_DATE, X200.CRE_DATE, X222.CRE_DATE, X225.CRE_DATE, X230.CRE_DATE)
                                                                                                                       CRE_DATE
     , COALESCE(X106.ORDER_TIME, X105.ORDER_TIME, X107.ORDER_TIME, X108.ORDER_TIME, X109.ORDER_TIME
                , X111.ORDER_TIME, X112.ORDER_TIME, X113.ORDER_TIME, X222.ORDER_TIME, null)
                                                                                                                       ORDER_TIME
     , COALESCE(TT.END_DATE, X102.END_DATE, X104.END_DATE, X105.END_DATE, X108.END_DATE
                , X109.END_DATE, X110.END_DATE, X112.END_DATE, X114.END_DATE, X200.END_DATE, X225.END_DATE)
                                                                                                                       END_DATE

     , COALESCE(X102.SUMM_$, X101.SUMM_$)                                                                              PAY_$

     , DECODE(X104.CHARGE_VALUE, 0, null, X104.CHARGE_VALUE)                                                           CHARGE_$

     , COALESCE(
         REGEXP_REPLACE(
          REGEXP_REPLACE(
                  coalesce(
                          REGEXP_SUBSTR(tt.COMMENT_2, (select REGEXP_01 from SETTING)),
                          REGEXP_SUBSTR(tt.COMMENT_1, (select REGEXP_02 from SETTING)),
                          REGEXP_SUBSTR(tt.COMMENT_2, (select REGEXP_03 from SETTING)))
              , ':|\s|\.$|[[:alpha:]]', '')
              , ',', '.')
         , X225.BALANCE_$)                                                                                BALANCE_$

     , COALESCE(TT.TRPL_SERV, X104.TRPL_SERV, X105.TRPL_SERV, X106.TRPL_SERV, X107.TRPL_SERV, X108.TRPL_SERV,
                X109.TRPL_SERV, X110.TRPL_SERV, X111.TRPL_SERV, X112.TRPL_SERV, X113.TRPL_SERV, X114.TRPL_SERV
                , X200.TRPL_SERV, X222.TRPL_SERV, X225.TRPL_SERV, X230.TRPL_SERV)
                                                                                                          TRPL_SERV
     , COALESCE(TT.COMMENT_1, X102.COMMENT_1, X104.COMMENT_1, X101.COMMENT_1, X106.COMMENT_1
                , X105.COMMENT_1, X107.COMMENT_1, X108.COMMENT_1, X109.COMMENT_1, X110.COMMENT_1
                , X111.COMMENT_1, X112.COMMENT_1, X113.COMMENT_1, X114.COMMENT_1, X200.COMMENT_1
                , X222.COMMENT_1, X225.COMMENT_1, X230.COMMENT_1)
                                                                                                          COMMENTS_1
     , COALESCE(TT.COMMENT_2, X104.COMMENT_2, X101.COMMENT_2, X105.COMMENT_2, X106.COMMENT_2
                , X107.COMMENT_2, X108.COMMENT_2, X109.COMMENT_2, X110.COMMENT_2
                , X111.COMMENT_2, X112.COMMENT_2, X113.COMMENT_2, X114.COMMENT_2
                , X200.COMMENT_2, X222.COMMENT_2, X225.COMMENT_2, X230.COMMENT_2)
                                                                                                          COMMENTS_2

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
         FULL OUTER JOIN X110 ON TT.TNAME = X110.TNAME
         FULL OUTER JOIN X111 ON TT.TNAME = X111.TNAME
         FULL OUTER JOIN X112 ON TT.TNAME = X112.TNAME
         FULL OUTER JOIN X113 ON TT.TNAME = X113.TNAME
         FULL OUTER JOIN X114 ON TT.TNAME = X114.TNAME
         FULL OUTER JOIN X200 ON TT.TNAME = X200.TNAME
         FULL OUTER JOIN X222 ON TT.TNAME = X222.TNAME
         FULL OUTER JOIN X225 ON TT.TNAME = X225.TNAME
         FULL OUTER JOIN X230 ON TT.TNAME = X230.TNAME

ORDER BY COALESCE(  DD.D_A_T_E, TT.CRE_DATE, X101.CRE_DATE, X102.CRE_DATE, X104.CRE_DATE
                  , X105.CRE_DATE, X106.CRE_DATE, X107.CRE_DATE, X108.CRE_DATE, X109.CRE_DATE
                  , X110.CRE_DATE, X111.CRE_DATE, X112.CRE_DATE, X113.CRE_DATE, X114.CRE_DATE
                  , X200.CRE_DATE, X222.CRE_DATE, X225.CRE_DATE, X230.CRE_DATE)
        , TNAME
        , COALESCE(  TT.TRPL_SERV, X104.TRPL_SERV, X105.TRPL_SERV, X106.TRPL_SERV, X107.TRPL_SERV
                   , X108.TRPL_SERV, X109.TRPL_SERV, X110.TRPL_SERV, X111.TRPL_SERV, X112.TRPL_SERV
                   , X113.TRPL_SERV, X114.TRPL_SERV, X200.TRPL_SERV)
        , COALESCE(  X111.COMMENT_1, X113.COMMENT_1,X114 .COMMENT_1, X110.COMMENT_1, X225.COMMENT_1, X230.COMMENT_1)
        , COALESCE(  X102.SUMM_$, X104.CHARGE_VALUE) desc
