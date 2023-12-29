DECLARE
	v_CLICLEF_ORIGEN	NUMBER;
	v_CLICLEF_DESTINO	NUMBER;
	v_CREATED_BY		VARCHAR2(30);
	v_MAX_SEQ			NUMBER;
	v_MAX_ID			NUMBER;
	v_DIFF				NUMBER;
	cons				NUMBER;
	i					NUMBER;
	
	
BEGIN
	-- ======================== --
	-- Asignación de valores    --
	-- ======================== --
	v_CLICLEF_ORIGEN := 22697;
	v_CLICLEF_DESTINO := 22726;
	v_CREATED_BY := 'A SOLICITUD ESTEPHANIAGH';


	-- ================================ --
	-- Emparejar SEQ con valor M�?XIMO   --
	-- ================================ --
	SELECT	 logis.seq_cil.NEXTVAL
		INTO v_MAX_SEQ
	FROM	 dual;
	
	SELECT	 MAX(cilclave)
		INTO v_MAX_ID
	FROM	 eclient_cliente_liga;
	
	v_DIFF := v_MAX_ID - v_MAX_SEQ;
	
	FOR i in 1..v_DIFF LOOP
		SELECT	 logis.seq_cil.NEXTVAL
			INTO cons
		FROM	 dual;
	END LOOP;


	-- ======================== --
	--	Registro de información --
	-- ======================== --
	INSERT INTO eclient_cliente_liga
		(SELECT	logis.seq_cil.NEXTVAL,
				v_CLICLEF_DESTINO, --nuevo cliente
				c1.cil_cclclave, v_CREATED_BY,
				SYSDATE, NULL, NULL,
				c1.cil_num_cliente_client, c1.cil_res_pres_completas, c1.cil_cliclef_fact,
				c1.cil_instr_cobranza, c1.cil_instr_evid, c1.cilaplica_cobro_tienda, c1.cilcontacto_dato
		 FROM	ECLIENT_CLIENTE_LIGA c1
		 WHERE	c1.cil_cliclef = v_CLICLEF_ORIGEN  -- antiguo cliente
			AND	NOT EXISTS	(SELECT	1 FROM ECLIENT_CLIENTE_LIGA c2
							 WHERE	c2.CIL_CCLCLAVE = c1.cil_cclclave
								AND	c2.cil_cliclef = v_CLICLEF_DESTINO) --nuevo cliente
		);
	
	INSERT INTO	edireccion_entr_cliente_liga
		(SELECT	GET_DECCLAVE,
				v_CLICLEF_DESTINO, --nuevo cliente
				dec_dieclave, dec_num_dir_cliente, v_CREATED_BY,
				SYSDATE, NULL, NULL,
				dec_tipo_direccion, dec_dieclave_entrega, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL, NULL
		 FROM	edireccion_entr_cliente_liga dec2
		 WHERE	dec2.dec_cliclef = v_CLICLEF_ORIGEN -- antiguo cliente
			AND	NOT EXISTS	(SELECT	1 FROM edireccion_entr_cliente_liga dec3
							 WHERE	dec3.dec_dieclave = dec2.dec_dieclave
								AND	dec3.dec_cliclef = v_CLICLEF_DESTINO) --nuevo cliente
		);
	
	INSERT INTO	edistributeur
		(SELECT	next1('DIS_SEQ'),
				v_CLICLEF_DESTINO, --nuevo cliente
				disnom, disnumero+3, disadresse1, disadresse2, discodepostal,
				disville, distelephone, disfax, distax, discontact, dispostecontact, disvinculo,
				distipo, v_CREATED_BY,
				SYSDATE, NULL, NULL, disnumext, disnumint, disetat, dis_emp_logis, disemail,
				dis_inmex, disclvplanta, dis_fec_validprov, dis_tmuclave, dis_ttdclave, disfecini,
				disfecfin, dis_grpclave, DIS_ALLCLAVE, DIS_FORANEO, dis_dieclave
		 FROM	edistributeur
		 WHERE	disclient = v_CLICLEF_ORIGEN -- antiguo cliente
			AND	disnumero != 0
		);


	-- ============== --
	-- COMPROBACIÓN   --
	-- ============== --
	--SELECT * FROM edistributeur WHERE DISCLIENT IN (v_CLICLEF_ORIGEN,v_CLICLEF_DESTINO) ORDER BY DISCLIENT;
END;