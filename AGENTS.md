# Agent instructions for SNMP::Info

SNMP::Info is a Perl library that presents network devices behind one
method API over SNMP. Netdisco is its main consumer; other applications use
it directly, so keep code, comments and PR text library-neutral.

Before writing or changing a device class, read
`.claude/skills/device-class-authoring/SKILL.md`. Before reviewing a branch
or pull request, including your own before you open it, read
`.claude/skills/device-class-review/SKILL.md`.

## How the library works

The developer reference is the `EXTENDING SNMP::INFO` section of
`lib/SNMP/Info.pm`, with a sample subclass. In short:

- **Methods are generated, not written.** `AUTOLOAD` in `SNMP/Info.pm`
  makes a method from any leaf a loaded MIB defines: a GET for a scalar,
  a walk returning a hashref keyed by instance id (iid) for a table
  column. Four package hashes name and shape these methods:
  - `%GLOBALS`: `method => 'scalarLeaf'`, read with GET.
  - `%FUNCS`: `method => 'tableColumn'`, walked.
  - `%MIBS`: `'MIB-NAME' => 'probeLeaf'`, MIBs that must load.
  - `%MUNGE`: `method => \&formatter`, post-processing.
- **List what the class reads.** By convention each leaf a class reads
  has a `%GLOBALS` or `%FUNCS` entry, so the top of the file shows its
  sources. A sub may call a leaf by its MIB name instead
  (`jnxContentsDescr` in `Layer3/Juniper.pm`), or to bypass an override
  of the friendly method (`e_index` in `Entity.pm`). Comment which MIB
  the leaf comes from.
- **Leaf names come from MIBs.** A `%FUNCS` or `%GLOBALS` value may also be
  a numeric OID. Since 3.981002, table columns walk correctly whether or
  not a loaded MIB defines them; earlier releases return undef for a
  column no loaded MIB defines. Prefix a leaf with its MIB to resolve name
  collisions (`ALTEON_TIGON_SWITCH_MIB__agSoftwareVersion`).
- **Subclasses merge their parents' hashes, and the last key wins:**

  ```perl
  %MIBS    = (%SNMP::Info::Layer3::MIBS, 'VENDOR-MIB' => 'probeLeaf');
  %GLOBALS = (%SNMP::Info::Layer3::GLOBALS, ...);
  %FUNCS   = (%SNMP::Info::Layer3::FUNCS, %SNMP::Info::LLDP::FUNCS, ...);
  %MUNGE   = (%SNMP::Info::Layer3::MUNGE, ...);
  ```

  - A key two parents define takes the later parent's value. Put the
    class's own entries last so they override both.
  - Subs resolve the other way: the first `@ISA` parent that defines one
    wins. List parents in the hashes in reverse `@ISA` order, so a
    collision resolves to the same parent either way (`Layer3/Cisco.pm`).
    A mismatch passes every test until two parents share a key.
  - A sub anywhere in the inheritance beats a hash entry, even the class's
    own: `can()` looks for real subs first. Override a parent's sub with a
    sub.
  - `SUPER::x` follows `@ISA` only to real subs. For a generated method it
    reads the object's own merged hash, so a class that remaps `x` gets
    its own leaf back, not the parent's.
  - A sub that wraps its own hash entry calls `orig_x`, which skips every
    sub named `x` (`i_name` in `Layer3.pm`). To read a specific leaf
    whatever the hashes say, call it by MIB name; the comment in
    `Layer3/Enterasys.pm` `interfaces` weighs all three.

- **Inheritance is a mixin web.** Feature roles (`Bridge`, `LLDP`, `CDP`,
  `Entity`, `PowerEthernet`, `IEEE802dot11`, ...) mix into the `Layer1` to
  `Layer7` bases; device classes live in `lib/SNMP/Info/Layer{1,2,3,7}/`.
- **Detection.** `device_type()` in `SNMP/Info.pm` picks the class from
  `sysServices` (layers), `sysDescr` and `sysObjectID` enterprise maps.
- **Method prefixes** keep areas apart: `i_*` interfaces, `c_*` topology,
  `bp_*`/`fw_*` bridge and forwarding, `e_*` entity, `peth_*` PoE,
  `qb_*` Q-BRIDGE. Use the prefix of the area you touch.

## Environment

- Build with Module::Build: `perl Build.PL && ./Build`.
- Needs the Net-SNMP Perl module (`SNMP`) and a copy of
  [netdisco-mibs](https://github.com/netdisco/netdisco-mibs) at
  `~/netdisco-mibs`. The test session loads every MIB directory there and
  ignores `MIBDIRS`.
- CI uses the latest netdisco-mibs **release**, not its master branch.
  `init()` croaks when a `%MIBS` entry does not load, so a class naming a
  MIB that is not yet released fails CI. Until the release ships, keep the
  class PR as a draft, or read the objects by numeric OID with a comment
  naming the pending netdisco-mibs PR. Adding a MIB follows that
  repository's own `AGENTS.md`.
- Style: `.perltidyrc` (78 columns, 4-space indent, no tabs).

## Tests

CI runs:

```sh
perl Build.PL && ./Build test --test_files t/ --test_files xt/
```

One class:

```sh
prove -Ilib -Ixt/lib xt/21_run.t :: Test::SNMP::Info::Layer3::Vendor
```

| Test | Fails when |
|---|---|
| `t/00_load.t` | a module does not compile |
| `xt/21_run.t` | a device test class fails, including `method_coverage` |
| `xt/00_local_docininfo.t` | a class is missing from the SUBCLASSES POD in `Info.pm` |
| `xt/00_local_pod-coverage.t` | a public method has no POD |
| `xt/00_local_pod.t` | POD is malformed |
| `xt/00_local_perlcritic.t` | perlcritic severity 5 is violated |
| `xt/00_local_versionsync.t` | module `$VERSION`s differ |

- `t/` holds only `00_load.t`. Device tests are Test::Class classes at
  `xt/lib/Test/SNMP/Info/Layer{N}/Vendor.pm`, inheriting
  `My::Test::Class`, mirroring the class path.
- `method_coverage` needs a test method named after **every** public sub
  the class defines. `Extra: 'model', 'vendor'` means those subs have no
  test method of the same name.
- Detection cases go in the class's own test class, in a `device_type`
  test method (`xt/lib/Test/SNMP/Info/Layer3/Siemens.pm`).
  `xt/lib/Test/SNMP/Info.pm` tests only the generic layer logic.
- `_layers` in cached data is the raw `sysServices` integer (`6`); the
  `layers` munge turns it into the bit string.
- Tests prime the mock session with `$test->{info}->cache({...})`. Build
  that data synthetically from real walks: same OIDs, index shapes and
  value forms. Never commit a raw walk.

## Before you open a pull request

- [ ] The CI command above passes locally.
- [ ] New class: test class in `xt/`, `=item` entry in the `Info.pm`
      SUBCLASSES POD, MANIFEST entries for both files.
- [ ] Class POD follows the outline in the authoring skill.
- [ ] `Changes`: one entry under the top, undated `Version` heading, in the
      form `* #PR Vendor: what changed (#issue)`. Add it once the PR number
      exists.
- [ ] Not edited: `$VERSION`, `README`, `META.json`, `META.yml`. Maintainers
      regenerate them at release.
- [ ] No raw walks, screenshots or other assets committed; attach them to
      the PR conversation instead.
- [ ] Any MIB the class names is in a netdisco-mibs release, or a
      netdisco-mibs PR adding it is linked.
- [ ] The PR body says what changed, why, and how it was verified, and
      closes the issue it fixes (`Closes #N`).

## Device data

Ask for, or attach, a numeric walk of the whole device:

```sh
snmpwalk -v2c -c <community> -ObentU <host> .1
```

Numeric output keeps objects no loaded MIB defines, and it loads into
SNMP simulators. Before anyone shares a walk, sanitize it as described in
"Removing sensitive data" under `EXTENDING SNMP::INFO` in
`lib/SNMP/Info.pm`: replace each sensitive value with one consistent
stand-in, in values and OID indexes alike, and keep OIDs, types and index
shapes intact. When helping someone capture a walk, walk them through
that list and have them read the result before posting.
