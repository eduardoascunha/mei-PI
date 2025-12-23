CREATE OR REPLACE FUNCTION new_order_transaction(
    in_w_id INTEGER,
    in_d_id INTEGER,
    in_c_id INTEGER,
    in_ol_supply_w_id INTEGER[],
    in_ol_i_id INTEGER[],
    in_ol_quantity INTEGER[]
)
RETURNS TABLE (
    w_tax_out DECIMAL(4,4),
    d_tax_out DECIMAL(4,4),
    o_id_out INTEGER,
    o_entry_d_out TIMESTAMP,
    ol_cnt_out INTEGER,
    ol_amount_out DECIMAL(12,2)[],
    total_amount_out DECIMAL(12,2),
    c_last_out VARCHAR(16),
    c_credit_out CHAR(2),
    c_discount_out DECIMAL(4,4),
    i_name_out VARCHAR(24)[],
    i_price_out DECIMAL(5,2)[],
    s_quantity_out INTEGER[],
    brand_generic_out CHAR(1)[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_w_tax DECIMAL(4,4);
    v_d_tax DECIMAL(4,4);
    v_d_next_o_id INTEGER;
    v_c_discount DECIMAL(4,4);
    v_c_last VARCHAR(16);
    v_c_credit CHAR(2);
    v_o_id INTEGER;
    v_o_entry_d TIMESTAMP;
    v_ol_cnt INTEGER;
    v_total_amount DECIMAL(12,2) := 0;
    v_ol_amount DECIMAL(12,2);
    v_i_price DECIMAL(5,2);
    v_i_name VARCHAR(24);
    v_i_data VARCHAR(50);
    v_s_quantity INTEGER;
    v_s_data VARCHAR(50);
    v_s_dist_info CHAR(24);
    v_brand_generic CHAR(1);
    v_o_all_local INTEGER := 1;
    v_item_not_found BOOLEAN := FALSE;
    v_ol_index INTEGER;
    v_ol_number INTEGER;
BEGIN
    v_ol_cnt := array_length(in_ol_i_id, 1);

    SELECT w.w_tax INTO v_w_tax FROM bmsql_warehouse w WHERE w.w_id = in_w_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Warehouse not found';
    END IF;

    SELECT d.d_tax, d.d_next_o_id INTO v_d_tax, v_d_next_o_id 
    FROM bmsql_district d 
    WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'District not found';
    END IF;

    UPDATE bmsql_district SET d_next_o_id = d_next_o_id + 1 
    WHERE d_w_id = in_w_id AND d_id = in_d_id 
    RETURNING d_next_o_id INTO v_d_next_o_id;

    SELECT c.c_discount, c.c_last, c.c_credit INTO v_c_discount, v_c_last, v_c_credit 
    FROM bmsql_customer c 
    WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found';
    END IF;

    v_o_id := v_d_next_o_id;
    v_o_entry_d := CURRENT_TIMESTAMP;

    FOR i IN 1..v_ol_cnt LOOP
        IF in_ol_supply_w_id[i] != in_w_id THEN
            v_o_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (in_w_id, in_d_id, v_o_id, in_c_id, NULL, v_ol_cnt, v_o_all_local, v_o_entry_d);

    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (in_w_id, in_d_id, v_o_id);

    FOR i IN 1..v_ol_cnt LOOP
        v_ol_index := i;
        v_ol_number := i;

        SELECT i.i_price, i.i_name, i.i_data INTO v_i_price, v_i_name, v_i_data 
        FROM bmsql_item i 
        WHERE i.i_id = in_ol_i_id[i];
        IF NOT FOUND THEN
            v_item_not_found := TRUE;
            EXIT;
        END IF;

        SELECT s.s_quantity, s.s_data, 
               CASE in_d_id 
                   WHEN 1 THEN s.s_dist_01 
                   WHEN 2 THEN s.s_dist_02 
                   WHEN 3 THEN s.s_dist_03 
                   WHEN 4 THEN s.s_dist_04 
                   WHEN 5 THEN s.s_dist_05 
                   WHEN 6 THEN s.s_dist_06 
                   WHEN 7 THEN s.s_dist_07 
                   WHEN 8 THEN s.s_dist_08 
                   WHEN 9 THEN s.s_dist_09 
                   WHEN 10 THEN s.s_dist_10 
               END INTO v_s_quantity, v_s_data, v_s_dist_info
        FROM bmsql_stock s 
        WHERE s.s_i_id = in_ol_i_id[i] AND s.s_w_id = in_ol_supply_w_id[i];
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Stock not found';
        END IF;

        v_ol_amount := in_ol_quantity[i] * v_i_price;
        v_total_amount := v_total_amount + v_ol_amount;

        IF v_s_quantity >= in_ol_quantity[i] + 10 THEN
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[i],
                s_ytd = s_ytd + in_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN in_ol_supply_w_id[i] != in_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_i_id = in_ol_i_id[i] AND s_w_id = in_ol_supply_w_id[i];
        ELSE
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[i] + 91,
                s_ytd = s_ytd + in_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN in_ol_supply_w_id[i] != in_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_i_id = in_ol_i_id[i] AND s_w_id = in_ol_supply_w_id[i];
        END IF;

        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            v_brand_generic := 'B';
        ELSE
            v_brand_generic := 'G';
        END IF;

        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (in_w_id, in_d_id, v_o_id, v_ol_number, in_ol_i_id[i], NULL, v_ol_amount, in_ol_supply_w_id[i], in_ol_quantity[i], v_s_dist_info);

        ol_amount_out[i] := v_ol_amount;
        i_name_out[i] := v_i_name;
        i_price_out[i] := v_i_price;
        s_quantity_out[i] := v_s_quantity;
        brand_generic_out[i] := v_brand_generic;
    END LOOP;

    IF v_item_not_found THEN
        ROLLBACK;
        w_tax_out := v_w_tax;
        d_tax_out := v_d_tax;
        o_id_out := v_o_id;
        c_last_out := v_c_last;
        c_credit_out := v_c_credit;
        RAISE EXCEPTION 'Item number is not valid';
    END IF;

    v_total_amount := v_total_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax);

    w_tax_out := v_w_tax;
    d_tax_out := v_d_tax;
    o_id_out := v_o_id;
    o_entry_d_out := v_o_entry_d;
    ol_cnt_out := v_ol_cnt;
    total_amount_out := v_total_amount;
    c_last_out := v_c_last;
    c_credit_out := v_c_credit;
    c_discount_out := v_c_discount;

    RETURN NEXT;
END;
$$;