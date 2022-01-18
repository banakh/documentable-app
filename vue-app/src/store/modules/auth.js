
const namespaced = true;

const state = {
  currentUser: undefined,
  loading: false,
};

const actions = {
  // async fetchCurrentUser({ commit }) {
  //
  // },
  // async logout({ commit }) {
  //
  // },
  // async login({ commit }, data) {
  //
  // },
  // async changePassword(_, data) {
  //
  // },
  // async resetPassword(_, data) {
  //   await axios.post("users/password", { user: data });
  // },
  // async updateCurrentUser({ commit }, userData) {
  //   let data, config;
  //   if (userData.file) {
  //     data = new FormData();
  //     data.append("user[file]", userData.file.raw);
  //     config = {
  //       headers: {
  //         "Content-Type": "multipart/form-data",
  //       },
  //     };
  //   } else if (userData.purgeLogo) {
  //     data = { user: { purgeLogo: true } };
  //   } else {
  //     data = userData;
  //   }
  //   const response = await axios.patch(`users/${userData.id}`, data, config);
  //   commit("setCurrentUser", response?.data);
  // },
  // async register(_, data) {
  //   await axios.post("users", { user: data });
  // },
  // async newPassword(_, data) {
  //   await axios.patch("users/password", { user: data });
  // },
};

const getters = {
  getCurrentUser: (state) => state.currentUser,
  isAuthenticated: (state) => !!state.currentUser,
  getLoading: (state) => !!state.loading,
};

const mutations = {
  setLoading: (state, payload) => (state.loading = payload),
  setCurrentUser: (state, payload) => (state.currentUser = payload),
};

export default {
  namespaced,
  state,
  getters,
  actions,
  mutations,
};
