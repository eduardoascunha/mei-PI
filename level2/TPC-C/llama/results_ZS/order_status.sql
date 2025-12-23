CREATE OR REPLACE FUNCTION order_status(
    p_w_id integer, 
    p_d_id integer, 
    p_c_id integer DEFAULT NULL, 
    p_c_last varchar(16) DEFAULT NULL
)
RETURNS TABLE (
    c_id integer, 
    c_first varchar(16), 
    c_middle char(2), 
    c_balance decimal(12,2), 
    o_id integer, 
    o_entry_d timestamp, 
    o_carrier_id integer, 
    ol_supply_w_id integer[], 
    ol_i_id integer[], 
    ol_quantity integer[], 
    ol_amount decimal(12,2)[], 
    ol_delivery_d timestamp[]
)
LANGUAGE plpgsql
AS $$
DECLARE 
    v_c_id integer;
    v_c_first varchar(16);
    v_c_middle char(2);
    v_c_balance decimal(12,2);
    v_o_id integer;
    v_o_entry_d timestamp;
    v_o_carrier_id integer;
    v_ol_cnt integer;
BEGIN
    IF p_c_id IS NOT NULL THEN
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance 
        INTO v_c_id, v_c_first, v_c_middle, v_c_balance 
        FROM bmsql_customer c 
        WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_id = p_c_id;
    ELSE
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance 
        INTO v_c_id, v_c_first, v_c_middle, v_c_balance 
        FROM (
            SELECT c_id, c_first, c_middle, c_balance, 
            ROW_NUMBER() OVER (ORDER BY c_first) as row_num,
            COUNT(*) OVER () as total_rows
            FROM bmsql_customer c 
            WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_last = p_c_last
        ) c 
        WHERE row_num = CEIL(total_rows / 2.0);
    END IF;

    SELECT o.o_id, o.o_entry_d, o.o_carrier_id 
    INTO v_o_id, v_o_entry_d, v_o_carrier_id 
    FROM bmsql_oorder o 
    WHERE o.o_w_id = p_w_id AND o.o_d_id = p_d_id AND o.o_c_id = v_c_id 
    ORDER BY o.o_id DESC LIMIT 1;

    SELECT COUNT(*) INTO v_ol_cnt 
    FROM bmsql_order_line ol 
    WHERE ol.ol_w_id = p_w_id AND ol.ol_d_id = p_d_id AND ol.ol_o_id = v_o_id;

    RETURN QUERY 
    SELECT 
        v_c_id, 
        v_c_first, 
        v_c_middle, 
        v_c_balance, 
        v_o_id, 
        v_o_entry_d, 
        v_o_carrier_id, 
        array_agg(ol.ol_supply_w_id ORDER BY ol.ol_number), 
        array_agg(ol.ol_i_id ORDER BY ol.ol_number), 
        array_agg(ol.ol_quantity ORDER BY ol.ol_number), 
        array_agg(ol.ol_amount ORDER BY ol.ol_number), 
        array_agg(ol.ol_delivery_d ORDER BY ol.ol_number)
    FROM bmsql_order_line ol 
    WHERE ol.ol_w_id = p_w_id AND ol.ol_d_id = p_d_id AND ol.ol_o_id = v_o_id;
END;
$$;