
select * 
from WEB_CAPTURA_PARAMETROS 
WHERE wcp_cliclef in (22359,20298,21413);

UPDATE WEB_CAPTURA_PARAMETROS 
SET WCP_CAPTURA_MANIF_II='S', -- null
    WCPNUEVA_ETIQUETA='S', -- null
    MODIFIED_BY='SISTEMAS', -- WEB_ADM o SISTEMAS
    DATE_MODIFIED=SYSDATE -- fecha o null
WHERE wcp_cliclef in (22359,20298,21413);