import { createApp } from "vue";
import App from "./App.vue";
import ElementPlus from "element-plus";
import urql from "@urql/vue";
import store from "./store";
import "element-plus/dist/index.css";
import "./styles/app.scss";
import router from "./router";
import { dedupExchange, fetchExchange, errorExchange } from "@urql/vue";
import { cacheExchange } from '@urql/exchange-graphcache';
import { devtoolsExchange } from '@urql/devtools';
createApp(App)
  .use(store)
  .use(router)
  .use(urql, {
    url: "/graphql",
    exchanges: [
      devtoolsExchange,
      dedupExchange,
      cacheExchange({
        keys: {
          Folder: data => {
            data['children'] = data?.documentsByFolderId?.nodes
            return data.id
          },
        },
      }),
      errorExchange({
        onError(error) {
          if (error.response?.status === 401) {
            localStorage.removeItem("authToken");
          }
          console.error("global console urql error:", error);
        }
      }),
      fetchExchange
    ],
    fetchOptions: () => {
      const token = localStorage.getItem("authToken");
      let headers = {};

      if (token&&token!=='null') {
        headers["authorization"] = `Bearer ${token}`;
      }else{
        headers["authorization"] = null
      }
      return {
        headers
      };
    }
  })
  .use(ElementPlus)
  .mount("#app");

