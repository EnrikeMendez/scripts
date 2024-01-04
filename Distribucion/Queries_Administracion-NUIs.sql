--	===================	--
--	 CUADRO DE CONTROL	--
--	===================	--
SELECT DISTINCT
LOTE
,FECHA
,TIPO
,NVL(TO_CHAR(MAX(FOLIO_FACTURA_INICIAL)),(CASE WHEN TOTAL_NUIS = GUIAS_CANCELADAS THEN 'N/A' ELSE '' END)) FOLIO_FACTURA_INICIAL
,NVL(TO_CHAR(MAX(FACTURA_INICIAL)),(CASE WHEN TOTAL_NUIS = GUIAS_CANCELADAS THEN 'N/A' ELSE '' END)) FACTURA_INICIAL
,NVL(TO_CHAR(IMPORTE_FACTURA),(CASE WHEN TOTAL_NUIS = GUIAS_CANCELADAS THEN 'N/A' ELSE '' END)) IMPORTE_FACTURA
,IMPORTE_POR_NUI
,TOTAL_NUIS
,GUIAS_DISPONIBLES
---------------------------------------
,GUIAS_OCUPADAS_SIN_ENTRADA GUIAS_OCUPADAS_SIN_ENTRADA
,GUIAS_OCUPADAS_CON_ENTRADA GUIAS_OCUPADAS_CON_ENTRADA
---------------------------------------
,GUIAS_CANCELADAS
---------------------------------------
,T.NOTA_CREDITO NUMERO_NOTA_CDTO
--,SYSDATE FECHA_NOTA_CDTO
,T.FECHA_NOTA_CREDITO FECHA_NOTA_CDTO
--,0 IMPORTE_NOTA_CDTO
,T.MONTO_NOTA_CREDITO IMPORTE_NOTA_CDTO
---------------------------------------
,FECHA_RESERVACION
,WEB_CLIENTE
,NVL(fecha_elaboracion,to_date('01/01/1900','dd/mm/yyyy')) fecha_elaboracion
FROM (
SELECT
DISTINCT
WL.LOTE
,TO_CHAR(WL.FECHA_RESERVACION,'dd/mm/yyyy') FECHA
,WL.TIPO
,FACTURA_INICIAL.FOLFOLIO FOLIO_FACTURA_INICIAL
,BASE.FACTURA_CUMPLE FACTURA_INICIAL
,BASE.SUBTOTAL IMPORTE_FACTURA
,WTS.PRECIO IMPORTE_POR_NUI
,WL.CANT_NUIS TOTAL_NUIS
,CASE WHEN WL.TIPO = 'LTL' THEN
( SELECT COUNT(1)
FROM web_tracking_stage wts_DIS
INNER JOIN WEB_LTL WEL_DIS ON WEL_DIS.WELclave = wts_DIS.nui
LEFT JOIN web_lots wl_DIS ON wl_DIS.lote = wts_DIS.numero_lote
WHERE wts_DIS.numero_lote IN (wl_DIS.lote)
AND (
(WEL_DIS.WELFACTURA = 'RESERVADO' AND WEL_DIS.WELSTATUS IN (1,3) AND TRUNC(WEL_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
OR (WEL_DIS.WELFACTURA = 'RESERVADA_STNDBY' AND WEL_DIS.WELSTATUS IN (1,3) AND TRUNC(WEL_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
)
AND wl_DIS.lote = wl.lote
)
ELSE
( SELECT COUNT(1)
FROM web_tracking_stage wts_DIS
INNER JOIN WCROSS_DOCK WCD_DIS ON WCD_DIS.WCDclave = wts_DIS.nui
LEFT JOIN web_lots wl_DIS ON wl_DIS.lote = wts_DIS.numero_lote
WHERE wts_DIS.numero_lote IN (wl_DIS.lote)
AND (
(WCD_DIS.WCDFACTURA = 'RESERVADO' AND WCD_DIS.WCDSTATUS IN (1,3) AND TRUNC(WCD_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
OR (WCD_DIS.WCDFACTURA = 'RESERVADA_STNDBY' AND WCD_DIS.WCDSTATUS IN (1,3) AND TRUNC(WCD_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
)
AND wl_DIS.lote = wl.lote
) END AS GUIAS_DISPONIBLES
,CASE WHEN WL.TIPO = 'LTL' THEN
( SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN WEB_LTL WEL_OCU ON WEL_OCU.WELclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WEL_OCU.WELSTATUS NOT IN (0, 3)
AND NOT (WEL_OCU.WELSTATUS = 1 AND WEL_OCU.WELFACTURA = 'RESERVADO')
AND TRUNC(WEL_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
---------------------------------------------------------------------------------------------------------------------------------------
AND (SELECT (CASE WHEN (WEL_ENTRADA.WELSTATUS NOT IN (0,3) AND TRA_ENTRADA.TRA_MEZTCLAVE_DEST IS NOT NULL) THEN '1' ELSE '0' END) TIENE_ENTRADA
FROM WEB_LTL WEL_ENTRADA
LEFT JOIN ETRANSFERENCIA_TRADING TRA_ENTRADA
ON WEL_ENTRADA.WEL_TRACLAVE = TRA_ENTRADA.TRACLAVE
WHERE WEL_ENTRADA.WELCLAVE = wts_OCU.NUI) = '1'
---------------------------------------------------------------------------------------------------------------------------------------
)
ELSE
( SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN wcross_dock wcd_OCU ON wcd_OCU.wcdclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WCD_OCU.WCDSTATUS NOT IN (0, 3)
AND NOT (WCD_OCU.WCDSTATUS = 1 AND WCD_OCU.WCDFACTURA = 'RESERVADO')
AND TRUNC(WCD_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
---------------------------------------------------------------------------------------------------------------------------------------
AND (SELECT (CASE WHEN (WCD_ENTRADA.WCDSTATUS NOT IN (0,3) AND TRA_ENTRADA.TRA_MEZTCLAVE_DEST IS NOT NULL) THEN '1' ELSE '0' END) TIENE_ENTRADA
FROM WCROSS_DOCK WCD_ENTRADA
LEFT JOIN ETRANSFERENCIA_TRADING TRA_ENTRADA
ON WCD_ENTRADA.WCD_TRACLAVE = TRA_ENTRADA.TRACLAVE
WHERE WCD_ENTRADA.WCDCLAVE = wts_OCU.NUI) = '1'
---------------------------------------------------------------------------------------------------------------------------------------
) END AS GUIAS_OCUPADAS_CON_ENTRADA
,CASE WHEN WL.TIPO = 'LTL' THEN
( SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN WEB_LTL WEL_OCU ON WEL_OCU.WELclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WEL_OCU.WELSTATUS NOT IN (0, 3)
AND NOT (WEL_OCU.WELSTATUS = 1 AND WEL_OCU.WELFACTURA = 'RESERVADO')
AND TRUNC(WEL_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
---------------------------------------------------------------------------------------------------------------------------------------
AND (SELECT (CASE WHEN (WEL_ENTRADA.WELSTATUS NOT IN (0,3) AND TRA_ENTRADA.TRA_MEZTCLAVE_DEST IS NOT NULL) THEN '1' ELSE '0' END) TIENE_ENTRADA
FROM WEB_LTL WEL_ENTRADA
LEFT JOIN ETRANSFERENCIA_TRADING TRA_ENTRADA
ON WEL_ENTRADA.WEL_TRACLAVE = TRA_ENTRADA.TRACLAVE
WHERE WEL_ENTRADA.WELCLAVE = wts_OCU.NUI) = '0'
---------------------------------------------------------------------------------------------------------------------------------------
)
ELSE
( SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN wcross_dock wcd_OCU ON wcd_OCU.wcdclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WCD_OCU.WCDSTATUS NOT IN (0, 3)
AND NOT (WCD_OCU.WCDSTATUS = 1 AND WCD_OCU.WCDFACTURA = 'RESERVADO')
AND TRUNC(WCD_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
---------------------------------------------------------------------------------------------------------------------------------------
AND (SELECT (CASE WHEN (WCD_ENTRADA.WCDSTATUS NOT IN (0,3) AND TRA_ENTRADA.TRA_MEZTCLAVE_DEST IS NOT NULL) THEN '1' ELSE '0' END) TIENE_ENTRADA
FROM WCROSS_DOCK WCD_ENTRADA
LEFT JOIN ETRANSFERENCIA_TRADING TRA_ENTRADA
ON WCD_ENTRADA.WCD_TRACLAVE = TRA_ENTRADA.TRACLAVE
WHERE WCD_ENTRADA.WCDCLAVE = wts_OCU.NUI) = '0'
---------------------------------------------------------------------------------------------------------------------------------------
) END AS GUIAS_OCUPADAS_SIN_ENTRADA
,CASE WHEN WL.TIPO = 'LTL' THEN
( SELECT COUNT(1)
FROM web_tracking_stage wts_CAN
INNER JOIN WEB_LTL WEL_CAN ON WEL_CAN.WELclave = wts_CAN.nui
LEFT JOIN web_lots wl_CAN ON wl_CAN.lote = wts_CAN.numero_lote
WHERE WEL_CAN.WELSTATUS = 0
AND wts_CAN.numero_lote = wl_CAN.lote
AND TRUNC(WEL_CAN.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_CAN.lote = wl.lote
)
ELSE
( SELECT COUNT(1)
FROM web_tracking_stage wts_CAN
INNER JOIN wcross_dock wcd_CAN ON wcd_CAN.wcdclave = wts_CAN.nui
LEFT JOIN web_lots wl_CAN ON wl_CAN.lote = wts_CAN.numero_lote
WHERE WCD_CAN.WCDSTATUS = 0
AND wts_CAN.numero_lote = wl_CAN.lote
AND TRUNC(WCD_CAN.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_CAN.lote = wl.lote
) END AS GUIAS_CANCELADAS
,WL.FECHA_RESERVACION
,WL.WEB_CLIENTE
,NOTA_CREDITO.FOLIO_NOTA_CREDITO
,NOTA_CREDITO.NOTA_CREDITO
--,NOTA_CREDITO.FECHA_NOTA_CREDITO
,TO_CHAR(NOTA_CREDITO.FECHA_NOTA_CREDITO,'DD/MM/YYYY') FECHA_NOTA_CREDITO
,REPLACE(NOTA_CREDITO.MONTO_NOTA_CREDITO,'-','') MONTO_NOTA_CREDITO
,BASE.fecha_elaboracion fecha_elaboracion
FROM WEB_LOTS WL
LEFT JOIN WEB_TRACKING_STAGE WTS
ON WL.LOTE = WTS.NUMERO_LOTE
LEFT JOIN (SELECT TO_NUMBER(fn.nui) AS nui
,f.fctclef AS fctclef
,f.fecha_timbrado
,TO_NUMBER(RTRIM(LTRIM(NVL(f.factura_cumple,0)))) FACTURA_CUMPLE
,f.Subtotal SUBTOTAL
,f.cliente
,f.fecha_elaboracion fecha_elaboracion
FROM tb_facturas_ccfdi f
JOIN tb_facturas_nuis_ccfdi fn
ON f.id_factura_cumple = fn.id_factura_cumple
WHERE 1=1
AND f.fctclef IS NOT NULL
AND f.cliente NOT IN (9954,9955,9956,9929,9910)
AND f.TIPO_CFDI = 'Ingreso'
AND f.STATUS_CFDI = 'T'
AND f.FECHA_TIMBRADO IS NOT NULL
AND f.FECHA_CANCELACION IS NULL
GROUP BY fn.nui,f.fctclef,f.fecha_timbrado,f.factura_cumple,f.Subtotal, f.cliente,f.fecha_elaboracion) BASE
ON WTS.NUI = BASE.NUI
AND WL.WEB_CLIENTE = BASE.CLIENTE
LEFT JOIN (SELECT fol.folfolio
,fct.fctnumero
,fct.fcttotingreso
,fct.fctuuid
,fct.fctclef
FROM efacturas fct
INNER JOIN efolios fol
ON fct.fctfolio = fol.folclave) FACTURA_INICIAL
ON BASE.fctclef = FACTURA_INICIAL.fctclef
LEFT JOIN (SELECT WL_NC.LOTE
,WL_NC.WEB_CLIENTE
,WL_NC.NCREDITO_FOLIO_PROFORMA
,FOL_NC.FOLCLAVE
,FOL_NC.FOLFOLIO AS FOLIO_NOTA_CREDITO
,FCT_NC.FCTNUMERO AS NOTA_CREDITO
--,WL_NC.NCREDITO_MONTO AS MONTO_NOTA_CREDITO
,FCT_NC.FCTTOTINGRESO AS MONTO_NOTA_CREDITO
,FCT_NC.FCTUUID AS UUID_NOTA_CREDITO
,FCT_NC.FCTDATEFACTURE AS FECHA_NOTA_CREDITO
FROM WEB_LOTS WL_NC
INNER JOIN EFOLIOS FOL_NC ON FOL_NC.FOLFOLIO = WL_NC.NCREDITO_FOLIO_PROFORMA
INNER JOIN EFACTURAS FCT_NC ON FCT_NC.FCTFOLIO = FOL_NC.FOLCLAVE
WHERE 1=1
AND FCT_NC.FCTUUID IS NOT NULL
AND FCT_NC.FCT_YFACLEF = '3' -- Nota de CrÃ©dito
AND (
INSTR(TRIM(REPLACE(UPPER(FCTOBSERVACIONES),CHR(13),'')),TRIM(UPPER(' No. Lote : ' || TO_CHAR(WL_NC.LOTE) || ' '))) > 0
OR
INSTR(TRIM(REPLACE(UPPER(FCTOBSERVACIONES),CHR(13),'')),TRIM(UPPER(' NO. LOTE: ' || TO_CHAR(WL_NC.LOTE) || ' '))) > 0
OR
INSTR(TRIM(REPLACE(UPPER(FCTOBSERVACIONES),CHR(13),'')),TRIM(UPPER('LOTE: ' || TO_CHAR(WL_NC.LOTE) || ' '))) > 0
)
) NOTA_CREDITO
ON WL.LOTE = NOTA_CREDITO.LOTE
WHERE 1=1
AND WL.WEB_CLIENTE = '10545'
) T
GROUP BY LOTE,FECHA,TIPO,IMPORTE_FACTURA,IMPORTE_POR_NUI,TOTAL_NUIS
,GUIAS_DISPONIBLES,GUIAS_OCUPADAS_CON_ENTRADA,GUIAS_OCUPADAS_SIN_ENTRADA,GUIAS_CANCELADAS
,FECHA_RESERVACION,WEB_CLIENTE
,T.NOTA_CREDITO,T.FECHA_NOTA_CREDITO,T.MONTO_NOTA_CREDITO,T.fecha_elaboracion,FOLIO_FACTURA_INICIAL,FACTURA_INICIAL
ORDER BY T.FECHA_RESERVACION DESC,T.LOTE,fecha_elaboracion DESC,nvl(FOLIO_FACTURA_INICIAL,0) DESC 
;

--	===================	--
--	 DETALLE LTL	--
--	===================	--
SELECT DISTINCT
WTS.NUI
,NUIS.FACTURA TALON_FACTURA
,REPLACE(UPPER(NUIS.ESTATUS),'RESERVADO','DISPONIBLE') STATUS
,TO_CHAR(WTS.FECHA_DOCUMENTACION,'DD/MM/YYYY HH24:MI:ss') FECHA_DOCUMENTA
,TO_CHAR(WTS.FECHA_CANCELACION,'DD/MM/YYYY HH24:MI:ss') FECHA_CANCELA
,NCARGO.FOLIO FOLIO_Nota_CARGO
,NCARGO.Nota_CARGO Nota_CARGO
,NVL2(NCARGO.FOLIO, WTS.PRECIO, NULL) IMPORTE_DEDUCIDO_NCARGO
,NCDTO.Folio_Nota_Credito
,NCDTO.Nota_Credito
,DECODE(UPPER(NUIS.ESTATUS),'CANCELADO',WTS.PRECIO, NULL) PRECIO_NOTA_CDTO
,NCDTO.MONTO_Nota_CREDITO
FROM WEB_LOTS WL
INNER JOIN WEB_TRACKING_STAGE WTS
ON WL.LOTE = WTS.NUMERO_LOTE
INNER JOIN (( SELECT LPAD (WELCONS_GENERAL, 7, 0)
|| '-'
|| GET_CLI_ENMASCARADO(wel_cliclef) AS factura,
DECODE (welstatus,
0, 'CANCELADO',
3, 'RESERVADO',
'DOCUMENTADO') AS estatus,
wel.welclave AS nui,
wel.wel_traclave AS traclave,
wel.wel_tdcdclave AS tdcdclave
,'LTL' AS tipo
FROM web_ltl wel
UNION ALL
SELECT wcdfactura AS factura,
DECODE (wcdstatus,
0, 'CANCELADO',
3, 'RESERVADO',
'DOCUMENTADO') AS estatus,
wcd.wcdclave AS nui,
wcd.wcd_traclave AS traclave,
wcd.wcd_tdcdclave AS tdcdclave
,'CrossDock' AS tipo
FROM wcross_dock wcd
)) NUIS
ON WTS.NUI = NUIS.nui
LEFT JOIN (SELECT fol_NCDTO.folfolio AS Folio_Nota_Credito,
max(fct.fctnumero) AS Nota_Credito,
wl_NCDTO.ncredito_monto AS MONTO_Nota_CREDITO,
wl_NCDTO.lote AS lote
FROM web_lots wl_NCDTO
INNER JOIN efolios fol_NCDTO ON wl_NCDTO.ncredito_folio_proforma = fol_NCDTO.folfolio
INNER JOIN efacturas fct ON fol_NCDTO.folclave = fct.fctfolio
WHERE 1=1
AND fct.fctUUID IS NOT NULL
AND fct.fct_yfaclef = '3'
AND (
INSTR(UPPER(fct.fctobservaciones),UPPER(' No. Lote : ' || TO_CHAR(wl_NCDTO.LOTE) || ' ')) > 0
OR
INSTR(UPPER(fct.fctobservaciones),UPPER(' NO. LOTE: ' || TO_CHAR(wl_NCDTO.LOTE) || ' ')) > 0
)
group by fol_NCDTO.folfolio,wl_NCDTO.ncredito_monto,wl_NCDTO.lote) NCDTO
ON WL.LOTE = NCDTO.LOTE
LEFT JOIN ((SELECT fol_NCARGO.folfolio AS FOLIO,
fct_NCARGO.fctnumero AS Nota_CARGO,
dtff.dtff_traclave AS traclave,
dtff.dtff_tdcdclave AS tdcdclave
FROM edet_trad_factura_cliente_fact dtff
LEFT JOIN edet_trad_factura_cliente dtfc ON dtfc.dtfcclave = dtff.dtff_dtfcclave
LEFT JOIN etrad_factura_cliente tfc ON tfc.tfcclave = dtfc.dtfc_tfcclave
JOIN tb_trans_hctrl hctrl ON hctrl.folclave_ori = tfc.tfc_folclave
JOIN efolios fol_NCARGO ON hctrl.folclave_ori = fol_NCARGO.folclave
JOIN efacturas fct_NCARGO ON fct_NCARGO.fctclef = hctrl.fctclef
)) NCARGO
ON NUIS.traclave = NCARGO.traclave
AND NUIS.tdcdclave = NCARGO.tdcdclave
WHERE 1 = 1
and NUIS.Tipo = 'LTL'
AND WL.WEB_CLIENTE = '10545'
AND WL.LOTE = '8091'
ORDER BY WTS.NUI DESC
;


--	===================	--
-- 	 DETALLE CROSS DOCK --
--	===================	--

SELECT DISTINCT
WTS.NUI
,NUIS.FACTURA TALON_FACTURA
,REPLACE(UPPER(NUIS.ESTATUS),'RESERVADO','DISPONIBLE') STATUS
,TO_CHAR(WTS.FECHA_DOCUMENTACION,'DD/MM/YYYY HH24:MI:ss') FECHA_DOCUMENTA
,TO_CHAR(WTS.FECHA_CANCELACION,'DD/MM/YYYY HH24:MI:ss') FECHA_CANCELA
,NCARGO.FOLIO FOLIO_Nota_CARGO
,NCARGO.Nota_CARGO Nota_CARGO
,NVL2(NCARGO.FOLIO, WTS.PRECIO, NULL) IMPORTE_DEDUCIDO_NCARGO
,NCDTO.Folio_Nota_Credito
,NCDTO.Nota_Credito
,DECODE(UPPER(NUIS.ESTATUS),'CANCELADO',WTS.PRECIO, NULL) PRECIO_NOTA_CDTO
,NCDTO.MONTO_Nota_CREDITO
FROM WEB_LOTS WL
INNER JOIN WEB_TRACKING_STAGE WTS
ON WL.LOTE = WTS.NUMERO_LOTE
INNER JOIN (( SELECT LPAD (WELCONS_GENERAL, 7, 0)
|| '-'
|| GET_CLI_ENMASCARADO(wel_cliclef) AS factura,
DECODE (welstatus,
0, 'CANCELADO',
3, 'RESERVADO',
'DOCUMENTADO') AS estatus,
wel.welclave AS nui,
wel.wel_traclave AS traclave,
wel.wel_tdcdclave AS tdcdclave
,'LTL' AS tipo
FROM web_ltl wel
UNION ALL
SELECT wcdfactura AS factura,
DECODE (wcdstatus,
0, 'CANCELADO',
3, 'RESERVADO',
'DOCUMENTADO') AS estatus,
wcd.wcdclave AS nui,
wcd.wcd_traclave AS traclave,
wcd.wcd_tdcdclave AS tdcdclave
,'CrossDock' AS tipo
FROM wcross_dock wcd
)) NUIS
ON WTS.NUI = NUIS.nui
LEFT JOIN (SELECT fol_NCDTO.folfolio AS Folio_Nota_Credito,
max(fct.fctnumero) AS Nota_Credito,
wl_NCDTO.ncredito_monto AS MONTO_Nota_CREDITO,
wl_NCDTO.lote AS lote
FROM web_lots wl_NCDTO
INNER JOIN efolios fol_NCDTO ON wl_NCDTO.ncredito_folio_proforma = fol_NCDTO.folfolio
INNER JOIN efacturas fct ON fol_NCDTO.folclave = fct.fctfolio
WHERE 1=1
AND fct.fctUUID IS NOT NULL
AND fct.fct_yfaclef = '3'
AND (
INSTR(UPPER(fct.fctobservaciones),UPPER(' No. Lote : ' || TO_CHAR(wl_NCDTO.LOTE) || ' ')) > 0
OR
INSTR(UPPER(fct.fctobservaciones),UPPER(' NO. LOTE: ' || TO_CHAR(wl_NCDTO.LOTE) || ' ')) > 0
)
group by fol_NCDTO.folfolio,wl_NCDTO.ncredito_monto,wl_NCDTO.lote) NCDTO
ON WL.LOTE = NCDTO.LOTE
LEFT JOIN ((SELECT fol_NCARGO.folfolio AS FOLIO,
fct_NCARGO.fctnumero AS Nota_CARGO,
dtff.dtff_traclave AS traclave,
dtff.dtff_tdcdclave AS tdcdclave
FROM edet_trad_factura_cliente_fact dtff
LEFT JOIN edet_trad_factura_cliente dtfc ON dtfc.dtfcclave = dtff.dtff_dtfcclave
LEFT JOIN etrad_factura_cliente tfc ON tfc.tfcclave = dtfc.dtfc_tfcclave
JOIN tb_trans_hctrl hctrl ON hctrl.folclave_ori = tfc.tfc_folclave
JOIN efolios fol_NCARGO ON hctrl.folclave_ori = fol_NCARGO.folclave
JOIN efacturas fct_NCARGO ON fct_NCARGO.fctclef = hctrl.fctclef
)) NCARGO
ON NUIS.traclave = NCARGO.traclave
AND NUIS.tdcdclave = NCARGO.tdcdclave
WHERE 1 = 1
and NUIS.Tipo = 'CrossDock'
AND WL.WEB_CLIENTE = '20235'
AND WL.LOTE = '8018'
ORDER BY WTS.NUI DESC
;



--	======================	--
--	 NUIs TODOS LOS LOTES	--
--	======================	--
SELECT
T.LOTE NO_LOTE
,T.TIPO TIPO
,TO_CHAR(T.FECHA_RESERVACION,'DD/MM/YYYY HH24:MI:ss') FECHA_DE_RESERVACION
,T.NUI NUI
,T.TALON TALON_FACTURA
,T.FOLIO_FACTURA_INICIAL FOLIO_FACTURA
,T.UUID_FACTURA_INICIAL UUID_CFDI_INGRESO
,T.IMPORTE_FACTURA_INICIAL IMPORTE_FACTURADO_LOTE
,T.IMPORTE_POR_NUI IMPORTE_FACTURADO_NUI
,INITCAP(T.ESTATUS) STATUS_NUI
FROM (
SELECT
DISTINCT
WL.LOTE
,TO_CHAR(WL.FECHA_RESERVACION,'dd/mm/yyyy') FECHA
,WL.TIPO
,FACTURA_INICIAL.FOLFOLIO FOLIO_FACTURA_INICIAL
,BASE.FACTURA_CUMPLE FACTURA_INICIAL
,FACTURA_INICIAL.fcttotingreso IMPORTE_FACTURA_INICIAL
,FACTURA_INICIAL.fctuuid UUID_FACTURA_INICIAL
,WTS.PRECIO IMPORTE_POR_NUI
,WL.CANT_NUIS TOTAL_NUIS
,CASE WHEN WL.TIPO = 'LTL' THEN
(SELECT COUNT(1)
FROM web_tracking_stage wts_DIS
INNER JOIN WEB_LTL WEL_DIS ON WEL_DIS.WELclave = wts_DIS.nui
LEFT JOIN web_lots wl_DIS ON wl_DIS.lote = wts_DIS.numero_lote
WHERE wts_DIS.numero_lote IN (wl_DIS.lote)
AND (
(WEL_DIS.WELFACTURA = 'RESERVADO' AND WEL_DIS.WELSTATUS IN (1,3) AND TRUNC(WEL_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
OR (WEL_DIS.WELFACTURA = 'RESERVADA_STNDBY' AND WEL_DIS.WELSTATUS IN (1,3) AND TRUNC(WEL_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
)
AND wl_DIS.lote = wl.lote
)
ELSE
(SELECT COUNT(1)
FROM web_tracking_stage wts_DIS
INNER JOIN WCROSS_DOCK WCD_DIS ON WCD_DIS.WCDclave = wts_DIS.nui
LEFT JOIN web_lots wl_DIS ON wl_DIS.lote = wts_DIS.numero_lote
WHERE wts_DIS.numero_lote IN (wl_DIS.lote)
AND (
(WCD_DIS.WCDFACTURA = 'RESERVADO' AND WCD_DIS.WCDSTATUS IN (1,3) AND TRUNC(WCD_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
OR (WCD_DIS.WCDFACTURA = 'RESERVADA_STNDBY' AND WCD_DIS.WCDSTATUS IN (1,3) AND TRUNC(WCD_DIS.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY'))
)
AND wl_DIS.lote = wl.lote
)
END AS GUIAS_DISPONIBLES
,CASE WHEN WL.TIPO = 'LTL' THEN
(SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN WEB_LTL WEL_OCU ON WEL_OCU.WELclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WEL_OCU.WELSTATUS NOT IN (0, 3)
AND NOT (WEL_OCU.WELSTATUS = 1 AND WEL_OCU.WELFACTURA = 'RESERVADO')
AND TRUNC(WEL_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
)
ELSE
(SELECT COUNT(1)
FROM web_tracking_stage wts_OCU
INNER JOIN wcross_dock wcd_OCU ON wcd_OCU.wcdclave = wts_OCU.nui
LEFT JOIN web_lots wl_OCU ON wl_OCU.lote = wts_OCU.numero_lote
WHERE wts_OCU.numero_lote = wl_OCU.lote
AND WCD_OCU.WCDSTATUS NOT IN (0, 3)
AND NOT (WCD_OCU.WCDSTATUS = 1 AND WCD_OCU.WCDFACTURA = 'RESERVADO')
AND TRUNC(WCD_OCU.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_OCU.lote = wl.lote
)
END AS GUIAS_OCUPADAS
,CASE WHEN WL.TIPO = 'LTL' THEN
(SELECT COUNT(1)
FROM web_tracking_stage wts_CAN
INNER JOIN WEB_LTL WEL_CAN ON WEL_CAN.WELclave = wts_CAN.nui
LEFT JOIN web_lots wl_CAN ON wl_CAN.lote = wts_CAN.numero_lote
WHERE WEL_CAN.WELSTATUS = 0
AND wts_CAN.numero_lote = wl_CAN.lote
AND TRUNC(WEL_CAN.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_CAN.lote = wl.lote
)
ELSE
(SELECT COUNT(1)
FROM web_tracking_stage wts_CAN
INNER JOIN wcross_dock wcd_CAN ON wcd_CAN.wcdclave = wts_CAN.nui
LEFT JOIN web_lots wl_CAN ON wl_CAN.lote = wts_CAN.numero_lote
WHERE WCD_CAN.WCDSTATUS = 0
AND wts_CAN.numero_lote = wl_CAN.lote
AND TRUNC(WCD_CAN.DATE_CREATED) >= TO_DATE('01/01/2021', 'DD/MM/YYYY')
AND wl_CAN.lote = wl.lote
)
END AS GUIAS_CANCELADAS
,WL.FECHA_RESERVACION
,WL.WEB_CLIENTE
,NUIS.NUI
,NUIS.FACTURA
,NUIS.TALON
,NUIS.ESTATUS
FROM WEB_LOTS WL
LEFT JOIN WEB_TRACKING_STAGE WTS
ON WL.LOTE = WTS.NUMERO_LOTE
LEFT JOIN (SELECT TO_NUMBER(fn.nui) AS nui
,f.fctclef AS fctclef
,f.fecha_timbrado
,TO_NUMBER(RTRIM(LTRIM(NVL(f.factura_cumple,0)))) FACTURA_CUMPLE
, f.cliente
FROM tb_facturas_ccfdi f
JOIN tb_facturas_nuis_ccfdi fn
ON f.id_factura_cumple = fn.id_factura_cumple
WHERE f.fctclef IS NOT NULL
AND f.cliente NOT IN (9954,9955,9956,9929,9910)
AND f.TIPO_CFDI = 'Ingreso'
AND f.STATUS_CFDI = 'T'
AND f.FECHA_TIMBRADO IS NOT NULL
AND f.FECHA_CANCELACION IS NULL
GROUP BY fn.nui,f.fctclef,f.fecha_timbrado,f.factura_cumple,f.cliente) BASE
ON WTS.NUI = BASE.NUI
AND WL.WEB_CLIENTE = BASE.CLIENTE
LEFT JOIN (SELECT fol.folfolio
,fct.fctnumero
,fct.fcttotingreso
,fct.fctuuid
,fct.fctclef
FROM efacturas fct
INNER JOIN efolios fol
ON fct.fctfolio = fol.folclave) FACTURA_INICIAL
ON BASE.fctclef = FACTURA_INICIAL.fctclef
INNER JOIN ((SELECT LPAD (WELCONS_GENERAL, 7, 0)
|| '-'
|| GET_CLI_ENMASCARADO(wel_cliclef) AS factura,
DECODE (welstatus,
0, 'CANCELADO',
3, 'DISPONIBLE',
'DOCUMENTADO') AS estatus,
wel.welclave AS nui,
wel.wel_traclave AS traclave,
wel.wel_tdcdclave AS tdcdclave,
'LTL' AS tipo,
WEL.WEL_TALON_RASTREO AS TALON
FROM web_ltl wel
WHERE TRUNC(wel.date_created) BETWEEN TO_DATE('01/12/2021','dd/mm/rrrr') AND TO_DATE(TO_CHAR(SYSDATE,'dd/mm/rrrr'),'dd/mm/rrrr')
UNION ALL
SELECT wcdfactura AS factura,
DECODE (wcdstatus,
0, 'CANCELADO',
3, 'DISPONIBLE',
'DOCUMENTADO') AS estatus,
wcd.wcdclave AS nui,
wcd.wcd_traclave AS traclave,
wcd.wcd_tdcdclave AS tdcdclave,
'CrossDock' AS tipo,
wcd.WCDFACTURA AS TALON
FROM wcross_dock wcd
WHERE TRUNC(wcd.date_created) BETWEEN TO_DATE('01/12/2021','dd/mm/rrrr') AND TO_DATE(TO_CHAR(SYSDATE,'dd/mm/rrrr'),'dd/mm/rrrr'))) NUIS
ON WTS.NUI = NUIS.nui
WHERE 1=1
AND WL.WEB_CLIENTE = '20235'
AND TRUNC(WL.FECHA_RESERVACION) BETWEEN TO_DATE('02/09/2023','dd/mm/yyyy') AND TO_DATE('01/11/2023','dd/mm/yyyy')
) T
ORDER BY T.FECHA_RESERVACION DESC, T.LOTE,T.NUI DESC,T.FACTURA_INICIAL DESC
;