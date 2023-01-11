-------------------------------------------------------------------------------
-- Title      : Network Wizard Ethernet package
-- Project    : netwiz
-- GitHub     : https://github.com/geddy11/netwiz
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
--!\file
--!\brief Ethernet library.
--
-------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2023 Geir Drange and contributors
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
--! @cond libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library nw_adapt;
use nw_adapt.nw_adaptations_pkg.all;
--library nw_util;
--context nw_util.nw_util_context;
use work.nw_types_pkg.all;
use work.nw_crc_pkg.all;
use work.nw_util_pkg.all;
--! @endcond

package nw_ethernet_pkg is

  -------------------------------------------------------------------------------
  -- Type definitions
  -------------------------------------------------------------------------------
  type t_dot1q is record
    tpid : std_logic_vector(15 downto 0);  --! Tag protocol identifier
    pcp  : std_logic_vector(2 downto 0);   --! Priority code point
    dei  : std_logic;                      --! Drop eligible indicator
    vid  : std_logic_vector(11 downto 0);  --! VLAN identifier
  end record t_dot1q;

  -- Ethernet II header
  type t_ethernet_header is record
    mac_dest  : t_slv_arr(0 to 5)(7 downto 0);  --! Destination MAC address
    mac_src   : t_slv_arr(0 to 5)(7 downto 0);  --! Source MAC address
    vlan_tag  : t_dot1q;                        --! VLAN tag (optional)
    ethertype : std_logic_vector(15 downto 0);  --! Ethertype
  end record t_ethernet_header;

  -------------------------------------------------------------------------------
  -- Constants
  -- Ethernet types source: https://en.wikipedia.org/wiki/EtherType
  -------------------------------------------------------------------------------
  constant C_ET_IPV4      : std_logic_vector(15 downto 0) := x"0800";  -- Internet Protocol version 4 (IPv4)
  constant C_ET_ARP       : std_logic_vector(15 downto 0) := x"0806";  -- Address Resolution Protocol (ARP)
  constant C_ET_WOL       : std_logic_vector(15 downto 0) := x"0842";  -- Wake-on-LAN[8]
  constant C_ET_AVTP      : std_logic_vector(15 downto 0) := x"22f0";  -- Audio Video Transport Protocol (AVTP)
  constant C_ET_TRILL     : std_logic_vector(15 downto 0) := x"22f3";  -- IETF TRILL Protocol
  constant C_ET_SRP       : std_logic_vector(15 downto 0) := x"22ea";  -- Stream Reservation Protocol
  constant C_ET_MOP       : std_logic_vector(15 downto 0) := x"6002";  -- DEC MOP RC
  constant C_ET_DNA       : std_logic_vector(15 downto 0) := x"6003";  -- DECnet Phase IV, DNA Routing
  constant C_ET_LAT       : std_logic_vector(15 downto 0) := x"6004";  -- DEC LAT
  constant C_ET_RARP      : std_logic_vector(15 downto 0) := x"8035";  -- Reverse Address Resolution Protocol (RARP)
  constant C_ET_APPLETALK : std_logic_vector(15 downto 0) := x"809b";  -- AppleTalk (Ethertalk)
  constant C_ET_AARP      : std_logic_vector(15 downto 0) := x"80f3";  -- AppleTalk Address Resolution Protocol (AARP)
  constant C_ET_VLAN      : std_logic_vector(15 downto 0) := x"8100";  -- VLAN-tagged frame (IEEE 802.1Q) and Shortest Path Bridging IEEE 802.1aq with NNI compatibility[9]
  constant C_ET_SLPP      : std_logic_vector(15 downto 0) := x"8102";  -- Simple Loop Prevention Protocol (SLPP)
  constant C_ET_VLACP     : std_logic_vector(15 downto 0) := x"8103";  -- Virtual Link Aggregation Control Protocol (VLACP)
  constant C_ET_IPX       : std_logic_vector(15 downto 0) := x"8137";  -- IPX
  constant C_ET_QNET      : std_logic_vector(15 downto 0) := x"8204";  -- QNX Qnet
  constant C_ET_IPV6      : std_logic_vector(15 downto 0) := x"86dd";  -- Internet Protocol Version 6 (IPv6)
  constant C_ET_EFC       : std_logic_vector(15 downto 0) := x"8808";  -- Ethernet flow control
  constant C_ET_LACP      : std_logic_vector(15 downto 0) := x"8809";  -- Ethernet Slow Protocols[10] such as the Link Aggregation Control Protocol (LACP)
  constant C_ET_COBRA     : std_logic_vector(15 downto 0) := x"8819";  -- CobraNet
  constant C_ET_MPLS_U    : std_logic_vector(15 downto 0) := x"8847";  -- MPLS unicast
  constant C_ET_MPLS_M    : std_logic_vector(15 downto 0) := x"8848";  -- MPLS multicast
  constant C_ET_PPPOE_DS  : std_logic_vector(15 downto 0) := x"8863";  -- PPPoE Discovery Stage
  constant C_ET_PPPEO_SS  : std_logic_vector(15 downto 0) := x"8864";  -- PPPoE Session Stage
  constant C_ET_MME       : std_logic_vector(15 downto 0) := x"887b";  -- HomePlug 1.0 MME
  constant C_ET_EAP       : std_logic_vector(15 downto 0) := x"888e";  -- EAP over LAN (IEEE 802.1X)
  constant C_ET_PROFINET  : std_logic_vector(15 downto 0) := x"8892";  -- PROFINET Protocol
  constant C_ET_SCSI      : std_logic_vector(15 downto 0) := x"889a";  -- HyperSCSI (SCSI over Ethernet)
  constant C_ET_ATA       : std_logic_vector(15 downto 0) := x"88a2";  -- ATA over Ethernet
  constant C_ET_ETHERCAT  : std_logic_vector(15 downto 0) := x"88a4";  -- EtherCAT Protocol
  constant C_ET_STAG      : std_logic_vector(15 downto 0) := x"88a8";  -- Service VLAN tag identifier (S-Tag) on Q-in-Q tunnel.
  constant C_ET_PL        : std_logic_vector(15 downto 0) := x"88ab";  -- Ethernet Powerlink
  constant C_ET_GOOSE     : std_logic_vector(15 downto 0) := x"88b8";  -- GOOSE (Generic Object Oriented Substation event)
  constant C_ET_GSE       : std_logic_vector(15 downto 0) := x"88b9";  -- GSE (Generic Substation Events) Management Services
  constant C_ET_SV        : std_logic_vector(15 downto 0) := x"88ba";  -- SV (Sampled Value Transmission)
  constant C_ET_ROMON     : std_logic_vector(15 downto 0) := x"88bf";  -- MikroTik RoMON (unofficial)
  constant C_ET_LLDP      : std_logic_vector(15 downto 0) := x"88cc";  -- Link Layer Discovery Protocol (LLDP)
  constant C_ET_SERCOS    : std_logic_vector(15 downto 0) := x"88cd";  -- SERCOS III
  constant C_ET_PHY       : std_logic_vector(15 downto 0) := x"88e1";  -- HomePlug Green PHY
  constant C_ET_MRP       : std_logic_vector(15 downto 0) := x"88e3";  -- Media Redundancy Protocol (IEC62439-2)
  constant C_ET_MACSEC    : std_logic_vector(15 downto 0) := x"88e5";  -- IEEE 802.1AE MAC security (MACsec)
  constant C_ET_PBB       : std_logic_vector(15 downto 0) := x"88e7";  -- Provider Backbone Bridges (PBB) (IEEE 802.1ah)
  constant C_ET_PTP       : std_logic_vector(15 downto 0) := x"88f7";  -- Precision Time Protocol (PTP) over IEEE 802.3 Ethernet
  constant C_ET_NC_SI     : std_logic_vector(15 downto 0) := x"88f8";  -- NC-SI
  constant C_ET_PRP       : std_logic_vector(15 downto 0) := x"88fb";  -- Parallel Redundancy Protocol (PRP)
  constant C_ET_CFM       : std_logic_vector(15 downto 0) := x"8902";  -- IEEE 802.1ag Connectivity Fault Management (CFM) Protocol / ITU-T Recommendation Y.1731 (OAM)
  constant C_ET_FCOE      : std_logic_vector(15 downto 0) := x"8906";  -- Fibre Channel over Ethernet (FCoE)
  constant C_ET_FCOE_IP   : std_logic_vector(15 downto 0) := x"8914";  -- FCoE Initialization Protocol
  constant C_ET_ROCE      : std_logic_vector(15 downto 0) := x"8915";  -- RDMA over Converged Ethernet (RoCE)
  constant C_ET_TTE       : std_logic_vector(15 downto 0) := x"891d";  -- TTEthernet Protocol Control Frame (TTE)
  constant C_ET_1905      : std_logic_vector(15 downto 0) := x"893a";  -- 1905.1 IEEE Protocol
  constant C_ET_HSR       : std_logic_vector(15 downto 0) := x"892f";  -- High-availability Seamless Redundancy (HSR)
  constant C_ET_CTP       : std_logic_vector(15 downto 0) := x"9000";  -- Ethernet Configuration Testing Protocol[11]
  constant C_ET_RT        : std_logic_vector(15 downto 0) := x"f1c1";  -- Redundancy Tag (IEEE 802.1CB Frame Replication and Elimination for Reliability)

  constant C_ETH_CRC32 : std_logic_vector(31 downto 0) := x"04C11DB7";

  constant C_DEFAULT_DOT1Q : t_dot1q := (tpid => x"0000", pcp => "111", dei => '0', vid => x"001");
  constant C_DEFAULT_ETH_HEADER : t_ethernet_header := (mac_dest  => (x"d1", x"d2", x"d3", x"d4", x"d5", x"d6"),
                                                        mac_src   => (x"51", x"52", x"53", x"54", x"55", x"56"),
                                                        vlan_tag  => C_DEFAULT_DOT1Q,
                                                        ethertype => C_ET_IPV4);

  -------------------------------------------------------------------------------
  -- Functions
  -------------------------------------------------------------------------------
  function f_eth_create_pkt(header     : t_ethernet_header;
                            payload    : t_slv_arr;
                            get_length : boolean := false) return t_slv_arr;

  function f_eth_get_header(eth_pkt : t_slv_arr) return t_ethernet_header;

  function f_eth_crc_ok(eth_pkt : t_slv_arr) return boolean;

  function f_eth_create_pkt_len(header  : t_ethernet_header;
                                payload : t_slv_arr) return natural;


end package nw_ethernet_pkg;

package body nw_ethernet_pkg is

  -------------------------------------------------------------------------------
  --! \brief Create ethernet packet
  --! \param header     Ethernet header
  --! \param payload    Ethernet payload
  --! \param get_length Get length of repacked array, default False
  --! \return           Ethernet packet (8bit array)
  --!
  --! Create ethernet packet. Payload must be 8bit data array. 4-byte FCS is added to the end of the packet.
  --! For VLAN tagging: Set header.vlan_tag.tpid = C_ET_VLAN.
  --!
  --! **Example use**
  --! ~~~
  --! v_eth_header  := C_DEFAULT_ETH_HEADER;
  --! v_packet_8bit := f_eth_create_pkt(v_eth_header, payload); 
  --! v_pkt_256bit  := f_repack(v_packet_8bit, 256);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_eth_create_pkt(header     : t_ethernet_header;
                            payload    : t_slv_arr;
                            get_length : boolean := false)
    return t_slv_arr is
    variable v_data   : t_slv_arr(0 to payload'length + 17)(7 downto 0);
    variable v_len    : natural;
    variable v_crc    : t_slv_arr(0 to 0)(31 downto 0);
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    assert payload'ascending report "f_eth_create_pkt: payload array must be ascending" severity C_SEVERITY;
    assert payload(payload'low)'length = 8 report "f_eth_create_pkt: payload must be 8bit" severity C_SEVERITY;

    -- header
    v_len := 12;
    for i in 0 to 5 loop
      v_data(i)   := header.mac_dest(i);
      v_data(6+i) := header.mac_src(i);
    end loop;
    if header.vlan_tag.tpid = C_ET_VLAN then
      v_data(12) := header.vlan_tag.tpid(15 downto 8);
      v_data(13) := header.vlan_tag.tpid(7 downto 0);
      v_data(14) := header.vlan_tag.pcp & header.vlan_tag.dei & header.vlan_tag.vid(11 downto 8);
      v_data(15) := header.vlan_tag.vid(7 downto 0);
      v_len      := 16;
    end if;
    v_data(v_len)     := header.ethertype(15 downto 8);
    v_data(v_len + 1) := header.ethertype(7 downto 0);
    v_len             := v_len + 2;
    -- payload
    for i in payload'low to payload'high loop
      v_data(v_len) := payload(i);
      v_len         := v_len + 1;
    end loop;
    -- add CRC
    v_crc(0)                   := not f_swap_endian(f_bitflip(f_gen_crc(C_ETH_CRC32, v_data(0 to v_len - 1), x"ffffffff", C_LSB_FIRST)));
    v_data(v_len to v_len + 3) := f_repack(v_crc, 8, C_MSB_FIRST);
    v_len                      := v_len + 4;
    if get_length then
      v_length(0) := std_logic_vector(to_unsigned(v_len, 31));
      return v_length;
    else
      return v_data(0 to v_len - 1);
    end if;
  end function f_eth_create_pkt;

  -------------------------------------------------------------------------------
  --! \brief Return length of ethernet packet.
  --! \param header     Ethernet header
  --! \param payload    Ethernet payload
  --! \return           Length of ethernet packet
  --!
  --! Return the length of the created ethernet packet.
  --!
  --! **Example use**
  --! ~~~
  --! v_len                      := f_eth_create_pkt(v_eth_header, payload, True); 
  --! v_pkt_8bit(0 to v_len - 1) := f_eth_create_pkt(v_eth_header, payload);
  --! ~~~
  -------------------------------------------------------------------------------
  function f_eth_create_pkt_len(header  : t_ethernet_header;
                                payload : t_slv_arr)
    return natural is
    variable v_length : t_slv_arr(0 to 0)(30 downto 0);
  begin
    v_length := f_eth_create_pkt(header, payload, true);
    return to_integer(unsigned(v_length(0)));
  end function f_eth_create_pkt_len;

  -------------------------------------------------------------------------------
  --! \brief Get ethernet header
  --! \param eth_pkt  Ethernet packet (8bit)
  --! \return         Ethernet header
  --!
  --! Extract ethernet header from ethernet packet. Assumes that first byte in packet is first byte after start frame delimiter.
  --!
  --! **Example use**
  --! ~~~
  --! v_eth_header := f_eth_get_header(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_eth_get_header(eth_pkt : t_slv_arr)
    return t_ethernet_header is
    variable v_header : t_ethernet_header;
    variable v_idx    : natural := eth_pkt'low;
    variable etype    : std_logic_vector(15 downto 0);
  begin
    assert eth_pkt'ascending report "f_eth_get_header: ethernet packet must be ascending" severity C_SEVERITY;
    assert eth_pkt'length >= 14 report "f_eth_get_header: ethernet packet must be at least 14 bytes" severity C_SEVERITY;

    v_header.mac_dest(0 to 5) := eth_pkt(v_idx to v_idx + 5);
    v_header.mac_src(0 to 5)  := eth_pkt(v_idx + 6 to v_idx + 11);
    etype                     := eth_pkt(v_idx + 12) & eth_pkt(v_idx + 13);
    v_header.ethertype        := etype;
    if etype = C_ET_VLAN then
      v_header.vlan_tag.tpid := C_ET_VLAN;
      v_header.vlan_tag.pcp  := eth_pkt(v_idx + 14)(7 downto 5);
      v_header.vlan_tag.dei  := eth_pkt(v_idx + 14)(4);
      v_header.vlan_tag.vid  := eth_pkt(v_idx + 14)(3 downto 0) & eth_pkt(v_idx + 15);
    else
      v_header.vlan_tag := C_DEFAULT_DOT1Q;
    end if;
    return v_header;
  end function f_eth_get_header;

  -------------------------------------------------------------------------------
  --! \brief Check CRC
  --! \param eth_pkt  Ethernet packet (8bit)
  --! \return         CRC is OK (True), or not (False)
  --!
  --! Check CRC of ethernet packet. Assumes that first byte in packet is first byte after start frame delimiter and the FCS are the last four bytes.
  --!
  --! **Example use**
  --! ~~~
  --! v_check := f_eth_crc_ok(data_array_8bit); 
  --! ~~~
  -------------------------------------------------------------------------------
  function f_eth_crc_ok(eth_pkt : t_slv_arr)
    return boolean is
    variable v_crc : t_slv_arr(0 to 0)(31 downto 0);
  begin
    assert eth_pkt'ascending report "f_eth_crc_ok: ethernet packet must be ascending" severity C_SEVERITY;
    assert eth_pkt'length >= 18 report "f_eth_crc_ok: ethernet packet must be at least 18 bytes" severity C_SEVERITY;

    v_crc(0) := not f_swap_endian(f_bitflip(f_gen_crc(C_ETH_CRC32, eth_pkt(eth_pkt'low to eth_pkt'high - 4), x"ffffffff", C_LSB_FIRST)));
    if f_repack(v_crc, 8, C_MSB_FIRST) = eth_pkt(eth_pkt'high - 3 to eth_pkt'high) then
      return true;
    else
      return false;
    end if;
  end function f_eth_crc_ok;

end package body nw_ethernet_pkg;
