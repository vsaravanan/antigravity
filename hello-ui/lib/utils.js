export const sleep = seconds => new Promise(res => setTimeout(res, seconds * 1000))
