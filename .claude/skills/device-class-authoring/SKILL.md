---
name: device-class-authoring
description: Use when adding or changing an SNMP::Info device class (lib/SNMP/Info/Layer*/Vendor.pm), its detection in device_type(), its tests or its POD, or when choosing between a standard MIB and a vendor MIB for a method.
---

# Writing SNMP::Info device classes

A class is judged by what the calling application can store from it.
Standard sources come first, vendor sources are fallbacks, and the class
reuses the patterns the library already has. Read `AGENTS.md` first; it
holds the build, test and pull request checklist.

## Start from an existing class

- Find the class with the nearest table shape and copy its approach:
  `Layer2/Aerohive.pm` (wireless, fixed `layers`), `Layer2/Baystack.pm`
  (standard first, vendor fallback), `Layer3/Foundry.pm` and
  `Layer3/Aruba.pm` (vendor PoE and port tables), `Airespace.pm`
  (merged controller tables).
- Inherit from the class the device resolved to before your change, so its
  behavior stays. A Net-SNMP based device that used to land on
  `Layer3::NetSNMP` keeps its `lo` handling and `hrSystemUptime` only if the
  new class inherits from `Layer3::NetSNMP`.
- Merge the parents' hashes in reverse `@ISA` order (`AGENTS.md`, "How
  the library works"). Copying a class that orders them otherwise copies
  the mismatch.
- Changing a shared role or a parent class (`Bridge.pm`, `LLDP.pm`,
  `Entity.pm`, `Airespace.pm`) affects every subclass. Check which classes
  inherit or override what you change, and test one of each.

## Detection

- Add the class to `device_type()` in `SNMP/Info.pm`: an enterprise map
  entry, a `sysDescr` pattern, or both.
- Register the narrowest `sysObjectID` branch that holds the product.
  A whole enterprise also captures the vendor's other product lines;
  the vendor's products MIB, or its MIB's top-level branches, show them.
- Every GET added to `device_type()` runs for every device that reaches
  it. Place a probe inside the narrowest branch (one enterprise, one
  `sysObjectID` prefix), never across a shared enterprise such as Net-SNMP
  `8072`.
- Anchor `sysDescr` patterns, and test that neighboring products still
  reach their own classes.
- When the device returns no `sysServices`, `layers` is undef and the
  calling application may skip it for forwarding tables. Override `layers`
  as `Layer2/Aerohive.pm` does.

## Choosing a data source

| Evidence in any walk of the vendor | Do |
|---|---|
| Standard (inherited method, IETF/IEEE MIB) present | Call the standard first, fall back to the vendor source. Comment why both exist. |
| Standard absent from every walk | Vendor source first. A standard fallback may follow it, since it is polled only when the vendor source returns nothing. Never poll an absent standard first. |
| No walk shows a source | Do not add it. Ask for a walk. |

- "Any walk" means every capture of the vendor available, not only one.
  Check what the class already inherits before concluding a standard is
  absent.
- Prefer IF-MIB values the device returns. Overriding `i_up`, `i_type` or
  similar from a vendor table needs a comment saying what IF-MIB gets wrong.
- Do not build `ip_index`/`ip_table` from the address SNMP::Info was asked
  to contact. It may be a NAT or proxy address, and the caller already
  knows it.

## Identity methods

- `vendor` and `os` return lowercase strings (`cisco meraki`, `rutos`).
- `model`: map known `sysObjectID`s; for unknown ones return
  `$self->SUPER::model()`, never undef.
- Search the vendor's MIBs in netdisco-mibs for model, serial and
  firmware version objects. Fill each one the device provides, and fall
  back to `SUPER::` when it returns nothing.
- Parse `sysDescr` with anchored patterns, and test the edge forms: a
  leading or trailing word, a missing field, a version with or without a
  `V` prefix.
- Tables with an active and an inactive row (firmware images) are read by
  their status column. Fall back to the first row only when no row has a
  status.

## Table methods

- Name MIB objects when netdisco-mibs defines them, and list the MIB in
  `%MIBS`. Use a numeric OID only when netdisco-mibs lacks or misnames the
  object, with a comment naming the object and the netdisco-mibs issue or
  PR.
- Since 3.981002, numeric OIDs in `%FUNCS` walk as table columns, with
  bulkwalk and caching. Do not write custom walkers or generate methods in
  a `no strict 'refs'` loop.
- A vendor MIB in netdisco-mibs is expected before a new class merges. Open
  the netdisco-mibs PR alongside the class; `AGENTS.md` explains how CI
  treats a MIB that is not yet released.
- With `UseEnums`, net-snmp applies a loaded MIB's enum even to a numeric
  read, for the values the enum defines. Munge labels back when needed.
- Fallbacks by kind: raw `%FUNCS` columns return undef when empty, so
  `$self->SUPER::x() || $self->vendor_x()` works. Derived methods return
  `{}`, which is true: test `keys %{...}`. Know what the inherited method
  already tries before adding one.
- One source per protocol per device. Decide it once and memoize it under
  an `_` key that `clear_cache` resets; empty walks are never cached. Mixed
  key formats between methods double neighbors.
- A table indexed by a TimeFilter (`dot1qVlanCurrentTable`,
  `dot1qFdbTable`, `lldpRemTable`) can walk forever on some agents: the
  index keeps increasing, so loop detection never fires. If a device's
  walk of one does not end, query with a partial of `0` (no time filter)
  and keep a fallback, as `Layer3/Enterasys.pm` does. Do it in the device
  class, not the shared role: agents that report rows only under their
  last-change timemark (Junos, Comware) may return nothing under `0`.
- Map vendor states into the standard's value set (PoE status is a
  `pethPsePortDetectionStatus` value, never `unknown`).
- Bridge port 0 means "not learned": drop it. Match a port number against
  the port field of `unit/slot/port`, never loosely.
- `topo()` merges every protocol; the caller deduplicates. A vendor
  neighbor table is another protocol beside LLDP and CDP, not a
  replacement. `has_topo` lists a protocol only when `can("hasX")` and
  `hasX()` are true: define `hasX` only for protocols the class supports,
  and make a vendor-backed `hasX` probe for data rather than return a
  constant.

## What the calling application reads

Netdisco, the main consumer, reads only these, so data elsewhere is not
stored. Its discover, macsuck and arpnip workers
(`App::Netdisco::Worker::Plugin::*`) are the reference.

- **Device**: `vendor`, `os`, `os_ver`, `model`, `serial`, `chassis_id`,
  `mac`, `layers`, `uptime`, `name`, `description`, `contact`,
  `location`, `ports`, `slots`, `fan`, `ps1_type`/`ps1_status`,
  `ps2_type`/`ps2_status`, `snmpEngineID`. Vendor environment tables
  belong in `fan` and `ps*_status`.
- **Addresses**: `ip_index`, `ip_table`, `ip_netmask`, `ipv6_addr`,
  `ipv6_index`, `ipv6_addr_prefixlength`, `ipv6_type`, `vrf_name`.
  Arpnip also takes subnets from `ip_netmask`.
- **Ports** keyed by `interfaces()`, minus those in `i_ignore`:
  `i_description`, `i_name` (ifAlias), `i_type`, `i_mtu`, `i_mac`,
  `i_up`/`i_up_admin`, `i_speed`/`i_speed_admin`/`i_speed_raw`,
  `i_duplex`/`i_duplex_admin`, `i_lastchange`, `i_vlan`, `i_stp_state`,
  `i_subinterfaces`, `agg_ports`, `i_err_disable_cause`,
  `i_faststart_enabled`. Ignore interfaces that are not ports (VLAN,
  loopback, management router interfaces) when the base class does not.
- **VLANs**: `v_name`, `v_index`, `i_vlan`, `i_vlan_type`,
  `i_vlan_membership`(`_untagged`). Compare a vendor VLAN table with
  Q-BRIDGE: one may list VLANs the other omits.
- **Forwarding** (devices with layer 2 in `layers`): `fw_mac` and
  `fw_port` through `bp_index` to `interfaces`, each entry's VLAN from
  `qb_fw_vlan`. Per-VLAN walks use `v_name`, `v_state`,
  `i_vlan_membership`, `i_auth_vlan_membership` and
  `cisco_comm_indexing`. `fw_status` is not read.
- **ARP and neighbor cache** (layer 3): `at_paddr`/`at_netaddr`,
  `ipv6_n2p_mac`/`ipv6_n2p_addr`.
- **Neighbors**: `has_topo`, then `c_ip` (and `lldp_ipv6`), `c_if`,
  `c_port`, `c_id`, `c_platform`, `c_cap`. Only entries with a `c_ip` are
  read. A `c_ip` that is unusable (`0.0.0.0`, loopback) is looked up by
  `c_id` as a name or MAC; an entry with no `c_ip` is dropped.
  `lldp_rem_vendor`, `lldp_rem_model`, `lldp_rem_serial`,
  `lldp_rem_sw_rev` and `lldp_media_cap` describe the far end.
- **Routing peers** queued for discovery: `bgp_peer_addr`, `ospf_peers`,
  `ospf_peer_id`, `isis_peers`, `eigrp_peers`.
- **Inventory**: `e_index`, `e_class`, `e_descr`, `e_name`, `e_type`,
  `e_model`, `e_serial`, `e_hwver`, `e_fwver`, `e_swver`, `e_fru`,
  `e_parent`, `e_pos`.
- **PoE**: `peth_power_watts`, `peth_power_status`, and `peth_port_*`
  (`admin`, `status`, `class`, `power`) keyed `module.port`, mapped to
  ports by `peth_port_ifindex`.
- **Wireless**: `i_ssidlist`, `i_ssidmac`, `i_ssidbcast`, `i_80211channel`,
  `dot11_cur_tx_pwr_mw`, keyed by interface. Clients from `cd11_*`.
- **802.1X**: `dot1x`, `pae_*`.

Vendor-named methods (`vendor_wifi_essid`) are not read. Emulate the
standard method from the vendor table instead.

## Tests

- One test class per device class, one test method per public sub.
- Test data is synthetic and derived from real walks at full fidelity: same
  OIDs, index shapes, value forms, edge cases. Never commit the walk.
- Every fallback path is exercised by a test, using data shaped like the
  walk that needs it.
- Add a `device_type` test method to the class's test class
  (`Layer3/Siemens.pm`): a case for each detection rule, and one showing
  a neighboring product still goes to its own class.

## POD

A new class uses this outline (`Layer2/Aerohive.pm`, `Layer2/Baystack.pm`):

```
=head1 NAME / AUTHOR (SNMP::Info Developers) / SYNOPSIS
=head1 DESCRIPTION
=head2 Inherited Classes      one =item per parent
=head2 Required MIBs          one F<MIB> item per %MIBS entry the class adds
=head2 Inherited MIBs         L<Parent/"Required MIBs"> per parent
=head1 GLOBALS
=head2 Overrides
=head2 Global Methods imported from <Parent>   one per parent
=head1 TABLE METHODS
=head2 Overrides
=head2 <Vendor> <Table Name> (C<vendorTable>)  one per vendor table
=head2 <Standard Feature> Table                emulation, with an intro:
       "These methods emulate the F<STD-MIB> C<stdTable> methods
        using the F<VENDOR-MIB> C<vendorTable>."
=head2 Table Methods imported from <Parent>    one per parent
=head1 Data Munging Callback Subroutines
```

- Each item is `=item $obj->method()`, a blank line, text saying what it
  returns and from where, and the leaf in `(C<leaf>)`. Table items start
  "Returns reference to hash."
- Document every `%GLOBALS`/`%FUNCS` entry and public sub the class
  defines, once. Inherited methods appear only in the "imported from"
  sections. Private `_` subs are not documented.
- A new class names `SNMP::Info Developers` under AUTHOR and as the
  copyright holder, not a person; git history records who wrote what. Keep the existing AUTHOR and
  copyright lines of a class you change.
- Check rendering with `pod2text`: each `=item` must render as its own
  heading.

## Files and Changes

- Add new files to `MANIFEST`. Do not edit `$VERSION`, `README` or
  `META.*`; maintainers set versions at release.
- `Changes`: under the top, undated `Version` heading, in the existing
  `[ENHANCEMENTS]` or `[BUG FIXES]` section, as
  `* #PR Vendor: what changed (#issue)`.
- PR text says what changed, why and how it was verified, and links
  related issues.
