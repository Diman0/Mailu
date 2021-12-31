variable "DOCKER_ORG" {
  default = "mailu"
}
variable "DOCKER_PREFIX" {
  default = ""
}
variable "PINNED_MAILU_VERSION" {
  default = "local"
}

# -----------------------------------------------------------------------------------------
group "default" {
  targets = [
    "docs",
    "setup",

    "admin",
    "antispam",
    "front",
    "imap",
    "smtp",

    "rainloop",
    "roundcube",

    "antivirus",
    "fetchmail",
    "resolver",
    "traefik-certdumper",
    "webdav"
  ]
}

target "defaults" {
  platforms = [ "linux/amd64", "linux/arm64", "linux/arm/v7" ]
  dockerfile="Dockerfile"
}

# -----------------------------------------------------------------------------------------
function "tag" {
  params = [image_name]
  result = "${DOCKER_ORG}/${DOCKER_PREFIX}${image_name}:${PINNED_MAILU_VERSION}"
}

# -----------------------------------------------------------------------------------------
# Documentation and setup images
# -----------------------------------------------------------------------------------------
target "docs" {
  inherits = ["defaults"]
  context = "docs"
  tags = [ tag("docs") ]
}

target "setup" {
  inherits = ["defaults"]
  context="setup"
  tags = [ tag("setup") ]
}

# -----------------------------------------------------------------------------------------
# Core images
# -----------------------------------------------------------------------------------------
target "none" {
  inherits = ["defaults"]
  context="core/none"
  tags = [ tag("none") ]
}

target "admin" {
  inherits = ["defaults"]
  context="core/admin"
  tags = [ tag("admin") ]
}

target "antispam" {
  inherits = ["defaults"]
  context="core/rspamd"
  tags = [ tag("rspamd") ]
}

target "front" {
  inherits = ["defaults"]
  context="core/nginx"
  tags = [ tag("nginx") ]
}

target "imap" {
  inherits = ["defaults"]
  context="core/dovecot"
  tags = [ tag("dovecot") ]
}

target "smtp" {
  inherits = ["defaults"]
  context="core/postfix"
  tags = [ tag("postfix") ]
}

# -----------------------------------------------------------------------------------------
# Webmail images
# -----------------------------------------------------------------------------------------
target "rainloop" {
  inherits = ["defaults"]
  context="webmails/rainloop"
  tags = [ tag("rainloop") ]
}

target "roundcube" {
  inherits = ["defaults"]
  context="webmails/roundcube"
  tags = [ tag("roundcube") ]
}

# -----------------------------------------------------------------------------------------
# Optional images
# -----------------------------------------------------------------------------------------
target "antivirus" {
  inherits = ["defaults"]
  context="optional/clamav"
  tags = [ tag("clamav") ]
}

target "fetchmail" {
  inherits = ["defaults"]
  context="optional/fetchmail"
  tags = [ tag("fetchmail") ]
}

target "resolver" {
  inherits = ["defaults"]
  context="optional/unbound"
  tags = [ tag("unbound") ]
}

target "traefik-certdumper" {
  inherits = ["defaults"]
  context="optional/traefik-certdumper"
  tags = [ tag("traefik-certdumper") ]
}

target "webdav" {
  inherits = ["defaults"]
  context="optional/radicale"
  tags = [ tag("radicale") ]
}
