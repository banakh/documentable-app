module.exports = {
  devServer: {
    proxy: {
      "^/graphql": {
        target: "http://localhost:5433",
        changeOrigin: true
      }
    }
  }
};
