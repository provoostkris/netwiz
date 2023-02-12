-------------------------------------------------------------------------------
-- Title      : Network Wizard Codec test bench
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Test bench for the NetWiz codec library.
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is 
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
-- IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library nw_util;
context nw_util.nw_util_context;

library nw_codec;
context nw_codec.nw_codec_context;

entity nw_codec_tb is
end entity nw_codec_tb;

architecture behav of nw_codec_tb is

  -- HDLC codec
  constant C_HDLC_CODEC : t_codec(0 to 1)(word(7 downto 0), code(0 to 1)(7 downto 0)) := ((word => x"7e", code => (x"7d", x"5e")),
                                                                                          (word => x"7d", code => (x"7d", x"5d")));

  constant C_HAMMING_7_4 : t_codec(0 to 15)(word(3 downto 0), code(0 to 0)(6 downto 0)) := ((word => x"0", code => (others => "0000000")),
                                                                                            (word => x"1", code => (others => "1101001")),
                                                                                            (word => x"2", code => (others => "0101010")),
                                                                                            (word => x"3", code => (others => "1000011")),
                                                                                            (word => x"4", code => (others => "1001100")),
                                                                                            (word => x"5", code => (others => "0100101")),
                                                                                            (word => x"6", code => (others => "1100110")),
                                                                                            (word => x"7", code => (others => "0001111")),
                                                                                            (word => x"8", code => (others => "1110000")),
                                                                                            (word => x"9", code => (others => "0011001")),
                                                                                            (word => x"a", code => (others => "1011010")),
                                                                                            (word => x"b", code => (others => "0110011")),
                                                                                            (word => x"c", code => (others => "0111100")),
                                                                                            (word => x"d", code => (others => "1010101")),
                                                                                            (word => x"e", code => (others => "0010110")),
                                                                                            (word => x"f", code => (others => "1111111")));

  constant C_TEST1 : t_slv_arr(0 to 10)(7 downto 0) := (x"01", x"01", x"01", x"05", x"01", x"01", x"01", x"01", x"01", x"01", x"01");

begin

  p_main : process
    variable v_data : t_slv_arr(0 to 15)(7 downto 0) := (x"00", x"67", x"7e", x"80", x"7d", x"7e", x"fe", x"7d",
                                                         x"45", x"5e", x"5d", x"7d", x"5d", x"ac", x"e1", x"01");
    variable v_data2    : t_slv_arr(0 to 8)(3 downto 0) := (x"e", x"1", x"6", x"f", x"0", x"b", x"3", x"c", x"2");
    variable v_enc2     : t_slv_arr(0 to 8)(6 downto 0);
    variable v_elen     : natural;
    variable v_dlen     : natural;
    variable v_enc      : t_slv_arr(0 to 31)(7 downto 0);
    variable v_dec      : t_slv_arr(0 to 31)(7 downto 0);
    variable v_dec2     : t_slv_arr(0 to 8)(3 downto 0);
    variable v_data3    : t_slv_arr(0 to 767)(7 downto 0);
    variable v_raw      : t_slv_arr(0 to 1023)(7 downto 0);
    variable v_cobs_enc : t_slv_arr(0 to 1023)(7 downto 0);
    variable v_cobs_dec : t_slv_arr(0 to 1023)(7 downto 0);
    variable v_init     : std_logic_vector(31 downto 0) := x"ffffffff";

  begin
    wait for 0.747 ns;
    -------------------------------------------------------------------------------
    -- nw_sl_codec_pkg functions
    -------------------------------------------------------------------------------
    msg("Part 1: Verify nw_sl_codec_pkg functions");
    v_elen := f_sl_enc_len(v_data, C_HDLC_CODEC);
    assert v_elen = 21
      report "Test 1.1 failed" severity failure;

    v_enc(0 to v_elen - 1) := f_sl_enc(v_data, C_HDLC_CODEC);

    v_dlen := f_sl_dec_len(v_enc(0 to v_elen - 1), C_HDLC_CODEC);
    assert v_dlen = 16
      report "Test 1.2 failed" severity failure;

    assert v_data = f_sl_dec(v_enc(0 to v_elen - 1), C_HDLC_CODEC)
      report "Test 1.3 failed" severity failure;

    wait for 2.89 ns;
    v_elen := f_sl_enc_len(v_data2, C_HAMMING_7_4);
    assert v_elen = 9
      report "Test 1.4 failed" severity failure;

    v_enc2(0 to v_elen - 1) := f_sl_enc(v_data2, C_HAMMING_7_4);

    wait for 1 ns;
    v_dlen := f_sl_dec_len(v_enc2(0 to v_elen - 1), C_HAMMING_7_4);
    assert v_dlen = 9
      report "Test 1.5 failed" severity failure;

    v_dec2 := f_sl_dec(v_enc2(0 to v_elen - 1), C_HAMMING_7_4);
    assert v_dec2 = v_data2
      report "Test 1.6 failed" severity failure;

    -------------------------------------------------------------------------------
    -- nw_cobs_pkg functions
    -------------------------------------------------------------------------------
    wait for 3.33 ns;
    msg("Part 2: Verify nw_cobs_pkg functions");

    v_data3(0 to 9) := (x"00", x"00", x"00", x"01", x"01", x"01", x"01", x"00", x"00", x"00");
    v_elen          := f_cobs_enc_len(v_data3(0 to 9));
    wait for 1 ns;
    assert v_elen = 11
      report "Test 2.1 failed" severity failure;

    v_data(0 to v_elen - 1) := f_cobs_enc(v_data3(0 to 9));
    assert v_data(0 to v_elen - 1) = C_TEST1
      report "Test 2.2 failed" severity failure;

    for i in 0 to 1000 loop
      v_raw(0 to i)               := f_gen_prbs(C_POLY_X32_X22_X2_X1_1, 8, i+1, C_MSB_FIRST, v_init);
      v_elen                      := f_cobs_enc_len(v_raw(0 to i));
      v_cobs_enc(0 to v_elen - 1) := f_cobs_enc(v_raw(0 to i));
      v_dlen                      := f_cobs_dec_len(v_cobs_enc(0 to v_elen - 1));
      assert v_dlen = i+1
        report "Test 2.3." & to_string(i+1) & " failed (length)" severity failure;

      v_cobs_dec(0 to v_dlen - 1) := f_cobs_dec(v_cobs_enc(0 to v_elen - 1));
      wait for 10 ps;
      assert v_raw(0 to i) = v_cobs_dec(0 to i)
        report "Test 2.3." & to_string(i+1) & " failed (data)" severity failure;

      v_init := v_raw(0) & v_raw(1) & v_raw(2) & v_raw(3);
    end loop;

    wait for 100 ns;
    -- Finish the simulation
    msg("All tests are pass!");
    std.env.stop;
    wait;                               -- to stop completely
  end process p_main;

end architecture behav;
