local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
}

config.errorStr = {
    [config.code.SUCCESS] = "Success",
    [config.code.FAILED] = "Failed",
}

config.offlineCode = {
    CLOSE = 1,
    TIMEOUT = 2,
    BAN = 3,
    MULTIPLE = 4,
}

config.offlineErrorStr = {
    [config.offlineCode.CLOSE] = "Close Success",
    [config.offlineCode.TIMEOUT] = "Time Out",
    [config.offlineCode.BAN] = "Ban",
    [config.offlineCode.MULTIPLE] = "Multiple Logins",
}

return config