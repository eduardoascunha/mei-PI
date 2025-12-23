CREATE OR REPLACE FUNCTION new_order(
    w_id_in integer,
    d_id_in integer,
    c_id_in integer,
    ol_supply_w_id_in integer[],
    ol_i_id_in integer[],
    ol_quantity_in integer[]
) RETURNS TABLE (
    w_tax decimal(4, 4),
    d_tax decimal(4, 4),
    o_id integer,
    o_entry_d timestamp,
    ol_cnt integer,
    total_amount decimal(12, 2),
    c_last varchar(16),
    c_credit char(2),
    c_discount decimal(4, 4),
    ol_supply_w_id_line integer,
    ol_i_id_line integer,
    i_name_line varchar(24),
    ol_quantity_line integer,
    s_quantity_line integer,
    brand_generic_line char(1),
    i_price_line decimal(5, 2),
    ol_amount_line decimal(6, 2),
    status_msg varchar
) AS $$
DECLARE
    v_w_tax decimal(4, 4);
    v_d_tax decimal(4, 4);
    v_o_id integer;
    v_c_discount decimal(4, 4);
    v_c_last varchar(16);
    v_c_credit char(2);
    v_o_entry_d timestamp := clock_timestamp();
    v_ol_cnt integer;
    v_o_all_local integer := 1;
    i integer;
    v_ol_i_id integer;
    v_ol_supply_w_id integer;
    v_ol_quantity integer;
    v_i_price decimal(5, 2);
    v_i_name varchar(24);
    v_i_data varchar(50);
    v_s_quantity integer;
    v_s_data varchar(50);
    v_s_dist char(24);
    v_ol_amount decimal(6, 2);
    v_brand_generic char(1);
    v_new_s_quantity integer;
    is_rollback boolean := false;
    v_sum_ol_amount decimal(12, 2) := 0.0;

    TYPE line_item_result IS RECORD (
        ol_supply_w_id integer,
        ol_i_id integer,
        i_name varchar(24),
        ol_quantity integer,
        s_quantity integer,
        brand_generic char(1),
        i_price decimal(5, 2),
        ol_amount decimal(6, 2)
    );
    line_item_results line_item_result[];
    current_line_item line_item_result;

BEGIN
    v_ol_cnt := array_length(ol_i_id_in, 1);

    SELECT w.w_tax INTO v_w_tax
    FROM bmsql_warehouse AS w
    WHERE w.w_id = w_id_in;

    UPDATE bmsql_district
    SET d_next_o_id = d_next_o_id + 1
    WHERE d_w_id = w_id_in AND d_id = d_id_in
    RETURNING d_tax, d_next_o_id - 1 INTO v_d_tax, v_o_id;

    SELECT c.c_discount, c.c_last, c.c_credit
    INTO v_c_discount, v_c_last, v_c_credit
    FROM bmsql_customer AS c
    WHERE c.c_w_id = w_id_in AND c.c_d_id = d_id_in AND c.c_id = c_id_in;

    FOR i IN 1 .. v_ol_cnt LOOP
        IF ol_supply_w_id_in[i] != w_id_in THEN
            v_o_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (w_id_in, d_id_in, v_o_id, c_id_in, NULL, v_ol_cnt, v_o_all_local, v_o_entry_d);

    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (w_id_in, d_id_in, v_o_id);

    FOR i IN 1 .. v_ol_cnt LOOP
        v_ol_i_id        := ol_i_id_in[i];
        v_ol_supply_w_id := ol_supply_w_id_in[i];
        v_ol_quantity    := ol_quantity_in[i];

        SELECT item.i_price, item.i_name, item.i_data
        INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item AS item
        WHERE item.i_id = v_ol_i_id;

        IF NOT FOUND THEN
            is_rollback := true;
            EXIT;
        END IF;

        SELECT s.s_quantity, s.s_data,
               CASE d_id_in
                   WHEN 1 THEN s.s_dist_01 WHEN 2 THEN s.s_dist_02
                   WHEN 3 THEN s.s_dist_03 WHEN 4 THEN s.s_dist_04
                   WHEN 5 THEN s.s_dist_05 WHEN 6 THEN s.s_dist_06
                   WHEN 7 THEN s.s_dist_07 WHEN 8 THEN s.s_dist_08
                   WHEN 9 THEN s.s_dist_09 WHEN 10 THEN s.s_dist_10
               END
        INTO v_s_quantity, v_s_data, v_s_dist
        FROM bmsql_stock AS s
        WHERE s.s_i_id = v_ol_i_id AND s.s_w_id = v_ol_supply_w_id;

        IF v_s_quantity >= v_ol_quantity + 10 THEN
            v_new_s_quantity := v_s_quantity - v_ol_quantity;
        ELSE
            v_new_s_quantity := v_s_quantity - v_ol_quantity + 91;
        END IF;

        UPDATE bmsql_stock
        SET s_quantity = v_new_s_quantity,
            s_ytd = s_ytd + v_ol_quantity,
            s_order_cnt = s_order_cnt + 1,
            s_remote_cnt = s_remote_cnt + (CASE WHEN v_ol_supply_w_id != w_id_in THEN 1 ELSE 0 END)
        WHERE s_i_id = v_ol_i_id AND s_w_id = v_ol_supply_w_id;

        v_ol_amount := v_ol_quantity * v_i_price;
        v_sum_ol_amount := v_sum_ol_amount + v_ol_amount;

        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            v_brand_generic := 'B';
        ELSE
            v_brand_generic := 'G';
        END IF;

        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (w_id_in, d_id_in, v_o_id, i, v_ol_i_id, NULL, v_ol_amount, v_ol_supply_w_id, v_ol_quantity, v_s_dist);

        current_line_item.ol_supply_w_id := v_ol_supply_w_id;
        current_line_item.ol_i_id        := v_ol_i_id;
        current_line_item.i_name         := v_i_name;
        current_line_item.ol_quantity    := v_ol_quantity;
        current_line_item.s_quantity     := v_s_quantity;
        current_line_item.brand_generic  := v_brand_generic;
        current_line_item.i_price        := v_i_price;
        current_line_item.ol_amount      := v_ol_amount;
        line_item_results := array_append(line_item_results, current_line_item);
    END LOOP;

    IF is_rollback THEN
        o_id := v_o_id;
        c_last := v_c_last;
        c_credit := v_c_credit;
        status_msg := 'Item number is not valid';
        RETURN NEXT;
    ELSE
        total_amount := v_sum_ol_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax);

        FOR i IN 1 .. array_length(line_item_results, 1) LOOP
            w_tax := v_w_tax;
            d_tax := v_d_tax;
            o_id := v_o_id;
            o_entry_d := v_o_entry_d;
            ol_cnt := v_ol_cnt;
            c_last := v_c_last;
            c_credit := v_c_credit;
            c_discount := v_c_discount;
            status_msg := NULL;

            ol_supply_w_id_line := line_item_results[i].ol_supply_w_id;
            ol_i_id_line        := line_item_results[i].ol_i_id;
            i_name_line         := line_item_results[i].i_name;
            ol_quantity_line    := line_item_results[i].ol_quantity;
            s_quantity_line     := line_item_results[i].s_quantity;
            brand_generic_line  := line_item_results[i].brand_generic;
            i_price_line        := line_item_results[i].i_price;
            ol_amount_line      := line_item_results[i].ol_amount;

            RETURN NEXT;
        END LOOP;
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql;