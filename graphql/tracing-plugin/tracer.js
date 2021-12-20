const { initTracer } = require("./tracing");

module.exports.tracer = initTracer("kong");
