select  WPLCLAVE id_registro, WPL_WELCLAVE NUI, WPL_IDENTICAS cantidad, WPL_TPACLAVE || ' (tarima)' tipo, WPL_CDAD_EMPAQUES_X_BULTO cajas_x_tarima, WPL_BULTO_TPACLAVE || ' (cajas de carton)' tipo_bulto,
        WPLLARGO largo, WPLANCHO ancho, WPLALTO alto, WPLPESO peso,
        CREATED_BY usuario_creacion, to_char(DATE_CREATED,'dd/mm/yyyy hh24:mi:ss') fecha_creacion, MODIFIED_BY usuario_modificacion, to_char(DATE_MODIFIED,'dd/mm/yyyy hh24:mi:ss') fecha_modificacion
from WPALETA_LTL 
where WPL_WELCLAVE = 9246972
;