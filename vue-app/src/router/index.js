import { createRouter, createWebHashHistory } from "vue-router";
import Home from "../views/Home.vue";
import Login from "../views/Login.vue";
import Register from "../views/Register.vue";
import Folders from "../views/group/Folders.vue";
import Document from "../views/group/Document.vue";

const routes = [
  {
    path: "/",
    name: "home",
    component: Home,
    meta: { requiresAuth: true },
    children: [
      {
        // UserProfile will be rendered inside User's <router-view>
        // when /user/:id/profile is matched
        path: '/folder/:groupId',
        name: "folder",
        component: Folders,
      },
      ]
  },
  {
    path: "/register",
    name: "register",
    component: Register
  },
  {
    path: "/document/:documentId",
    name: "document",
    component: Document
  },
  {
    path: "/login",
    name: "login",
    component: Login
  }
];

const router = createRouter({
  history: createWebHashHistory(),
  routes
});

router.beforeEach(async (to, from, next) => {
  const loggedIn = localStorage.getItem('authToken');
  if (to.meta?.requiresAuth && !loggedIn) {
    next({ name: "login", replace: true });
  } else {
    next();
  }
});

export default router;
