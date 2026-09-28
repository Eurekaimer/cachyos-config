// Global rules survive subscription updates and apply to every profile.
function main(config, profileName) {
  const directRules = [
    "DOMAIN-SUFFIX,bilibili.com,DIRECT",
    "DOMAIN-SUFFIX,bilivideo.com,DIRECT",
    "DOMAIN-SUFFIX,bilivideo.cn,DIRECT",
    "DOMAIN-SUFFIX,biliimg.com,DIRECT",
    "DOMAIN-SUFFIX,hdslb.com,DIRECT",
    "DOMAIN-SUFFIX,biliapi.com,DIRECT",
    "DOMAIN-SUFFIX,biliapi.net,DIRECT",
    "DOMAIN-SUFFIX,b23.tv,DIRECT",
    "GEOSITE,cn,DIRECT",
  ];
  const rules = config.rules || [];
  if (!rules.some(rule => /^GEOIP,CN,DIRECT(?:,|$)/i.test(rule))) {
    const fallback = rules.findIndex(rule => /^(MATCH|FINAL),/i.test(rule));
    rules.splice(fallback < 0 ? rules.length : fallback, 0, "GEOIP,CN,DIRECT");
  }
  config.rules = [...directRules, ...rules];
  return config;
}
