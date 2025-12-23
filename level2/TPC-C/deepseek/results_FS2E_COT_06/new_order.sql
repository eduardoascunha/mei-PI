CREATE OR REPLACE FUNCTION bmsql_proc_new_order(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_ol_supply_w_id integer[],
    IN in_ol_i_id integer[],
    IN in_ol_quantity integer[],
    OUT out_w_tax decimal(4,4),
    OUT out_d_tax decimal(4,4),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_ol_cnt integer,
    OUT out_ol_amount decimal(12,2)[],
    OUT out_total_amount decimal(12,2),
    OUT out_c_last varchar(16),
    OUT out_c_credit char(2),
    OUT out_c_discount decimal(4,4),
    OUT out_i_name varchar(24)[],
    OUT out_i_price decimal(5,2)[],
    OUT out_s_quantity integer[],
    OUT out_brand_generic char[]
) AS
$$
DECLARE
    v_d_next_o_id integer;
    v_c_discount decimal(4,4);
    v_i_price decimal(5,2);
    v_i_name varchar(24);
    v_i_data varchar(50);
    v_s_quantity integer;
    v_s_data varchar(50);
    v_s_dist_info char(24);
    v_ol_amount decimal(12,2);
    v_total_amount decimal(12,2) := 0;
    v_all_local integer := 1;
    v_ol_idx integer;
    v_item_found boolean;
BEGIN
    out_ol_cnt := array_length(in_ol_i_id, 1);
    
    SELECT w_tax INTO out_w_tax FROM bmsql_warehouse WHERE w_id = in_w_id;
    
    SELECT d_tax, d_next_o_id INTO out_d_tax, v_d_next_o_id 
    FROM bmsql_district WHERE d_w_id = in_w_id AND d_id = in_d_id;
    
    UPDATE bmsql_district SET d_next_o_id = d_next_o_id + 1 
    WHERE d_w_id = in_w_id AND d_id = in_d_id;
    
    SELECT c_last, c_credit, c_discount INTO out_c_last, out_c_credit, out_c_discount 
    FROM bmsql_customer WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_id = in_c_id;
    
    out_o_id := v_d_next_o_id;
    out_o_entry_d := CURRENT_TIMESTAMP;
    
    FOR v_ol_idx IN 1..out_ol_cnt LOOP
        IF in_ol_supply_w_id[v_ol_idx] != in_w_id THEN
            v_all_local := 0;
        END IF;
    END LOOP;
    
    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (in_w_id, in_d_id, out_o_id, in_c_id, NULL, out_ol_cnt, v_all_local, out_o_entry_d);
    
    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (in_w_id, in_d_id, out_o_id);
    
    FOR v_ol_idx IN 1..out_ol_cnt LOOP
        SELECT i_price, i_name, i_data INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item WHERE i_id = in_ol_i_id[v_ol_idx];
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Item number is not valid';
        END IF;
        
        out_i_name[v_ol_idx] := v_i_name;
        out_i_price[v_ol_idx] := v_i_price;
        
        SELECT s_quantity, s_data, 
               CASE in_d_id 
                   WHEN 1 THEN s_dist_01 
                   WHEN 2 THEN s_dist_02 
                   WHEN 3 THEN s_dist_03 
                   WHEN 4 THEN s_dist_04 
                   WHEN 5 THEN s_dist_05 
                   WHEN 6 THEN s_dist_06 
                   WHEN 7 THEN s_dist_07 
                   WHEN 8 THEN s_dist_08 
                   WHEN 9 THEN s_dist_09 
                   WHEN 10 THEN s_dist_10 
               END INTO v_s_quantity, v_s_data, v_s_dist_info
        FROM bmsql_stock 
        WHERE s_w_id = in_ol_supply_w_id[v_ol_idx] AND s_i_id = in_ol_i_id[v_ol_idx];
        
        out_s_quantity[v_ol_idx] := v_s_quantity;
        
        IF v_s_quantity >= in_ol_quantity[v_ol_idx] + 10 THEN
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[v_ol_idx],
                s_ytd = s_ytd + in_ol_quantity[v_ol_idx],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = s_remote_cnt + CASE WHEN in_ol_supply_w_id[v_ol_idx] != in_w_id THEN 1 ELSE 0 END
            WHERE s_w_id = in_ol_supply_w_id[v_ol_idx] AND s_i_id = in_ol_i_id[v_ol_idx];
        ELSE
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[v_ol_idx] + 91,
                s_ytd = s_ytd + in_ol_quantity[v_ol_idx],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = s_remote_cnt + CASE WHEN in_ol_supply_w_id[v_ol_idx] != in_w_id THEN 1 ELSE 0 END
            WHERE s_w_id = in_ol_supply_w_id[v_ol_idx] AND s_i_id = in_ol_i_id[v_ol_idx];
        END IF;
        
        v_ol_amount := in_ol_quantity[v_ol_idx] * v_i_price;
        out_ol_amount[v_ol_idx] := v_ol_amount;
        v_total_amount := v_total_amount + v_ol_amount;
        
        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            out_brand_generic[v_ol_idx] := 'B';
        ELSE
            out_brand_generic[v_ol_idx] := 'G';
        END IF;
        
        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, 
                                     ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (in_w_id, in_d_id, out_o_id, v_ol_idx, in_ol_i_id[v_ol_idx], NULL, 
                v_ol_amount, in_ol_supply_w_id[v_ol_idx], in_ol_quantity[v_ol_idx], v_s_dist_info);
    END LOOP;
    
    out_total_amount := v_total_amount * (1 - out_c_discount) * (1 + out_w_tax + out_d_tax);
END;
$$
LANGUAGE plpgsql;