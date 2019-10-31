local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
}

config.errorStr = {
    [config.code.SUCCESS] = "Status Success",
    [config.code.FAILED] = "Status Failed",
}

config.onlineStatus = {
    ONLINE = 1,
    OFFLINE = 2
}

return config