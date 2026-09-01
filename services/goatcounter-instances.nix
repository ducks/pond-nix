[
  {
    name = "jg";
    port = 8081;
    workDir = "/var/lib/goatcounter-jg";
    dbPath = "/var/lib/goatcounter-jg/goatcounter.db";
    vhosts = [ "stats.jakegoldsborough.com" ];
    dnsRecords = [ { domain = "jakegoldsborough.com"; host = "stats"; } ];
  }
  {
    name = "dv";
    port = 8082;
    workDir = "/var/lib/goatcounter-dv";
    dbPath = "/var/lib/goatcounter-dv/goatcounter.db";
    vhosts = [ "stats.date-ver.com" ];
    dnsRecords = [ { domain = "date-ver.com"; host = "stats"; } ];
  }
  {
    name = "gv";
    port = 8083;
    workDir = "/var/lib/goatcounter-gv";
    dbPath = "/var/lib/goatcounter-gv/goatcounter.db";
    vhosts = [ "stats.gnarlyvoid.com" ];
    dnsRecords = [ { domain = "gnarlyvoid.com"; host = "stats"; } ];
  }
  {
    name = "jl";
    port = 8084;
    workDir = "/var/lib/goatcounter-jl";
    dbPath = "/var/lib/goatcounter-jl/goatcounter.db";
    vhosts = [ "stats.jobl.dev" "stats.srg.jobl.dev" ];
    dnsRecords = [
      { domain = "jobl.dev"; host = "stats"; }
      { domain = "jobl.dev"; host = "stats.srg"; }
    ];
  }
  {
    name = "rb";
    port = 8086;
    workDir = "/var/lib/goatcounter-rb";
    dbPath = "/var/lib/goatcounter-rb/goatcounter.db";
    vhosts = [ "stats.replaybook.dev" ];
    dnsRecords = [ { domain = "replaybook.dev"; host = "stats"; } ];
  }
  {
    name = "azg";
    port = 8087;
    workDir = "/var/lib/goatcounter-azg";
    dbPath = "/var/lib/goatcounter-azg/goatcounter.db";
    vhosts = [ "stats.agentzen.garden" ];
    dnsRecords = [ { domain = "agentzen.garden"; host = "stats"; } ];
  }
  {
    name = "art";
    port = 8085;
    workDir = "/var/lib/goatcounter-art";
    dbPath = "/var/lib/goatcounter-art/goatcounter.db";
    vhosts = [ "stats.hausplants.art" "stats.birdhaus.art" ];
    dnsRecords = [
      { domain = "hausplants.art"; host = "stats"; }
      { domain = "birdhaus.art"; host = "stats"; }
    ];
  }
]
