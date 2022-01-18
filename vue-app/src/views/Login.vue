<template>
  <el-card class="box-card">
    <el-form ref="refLoginForm" :model="loginForm" :rules="rules">
      <el-form-item prop="email">
        <el-input
          placeholder="Enter Email"
          type="email"
          v-model="loginForm.username"
        ></el-input>
      </el-form-item>
      <el-form-item prop="password">
        <el-input
          placeholder="Enter Password"
          type="password"
          v-model="loginForm.password"
        ></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="submitForm('loginForm')"
        >Login
        </el-button>
      </el-form-item>
    </el-form>
    <el-alert v-if="errorMessage" :title="errorMessage" type="error" show-icon>
    </el-alert>
  </el-card>
  <el-card>
    <div style="font-size: 14px">
      Don't have an account?
      <router-link to="/register" custom v-slot="{ href, navigate }">
        <el-button :href="href" @click="navigate" type="text"
        >Sign up
        </el-button>
      </router-link>
    </div>
  </el-card>
</template>

<script setup>
import { ref, reactive } from "vue";
import { useRouter } from "vue-router";
import { useMutation } from "@urql/vue";


const router = useRouter();
const errorMessage = ref("");
const refLoginForm = ref(null);
const loginForm = reactive({
  username: "",
  password: ""
});

const rules = {
  username: [
    {
      required: true,
      trigger: "blur",
      message: "Please input user name"
    }
  ],
  password: [{ required: true, trigger: "change" }]
};

const authenticate = `
mutation authenticate($username: String!, $password: String!) {
  authenticate(input: {username: $username, password: $password}) {
    jwtToken
  }
}
`
const updateAuthenticate = useMutation(authenticate);
function submitForm() {
  refLoginForm.value.validate(async (valid) => {
    if (valid) {
      const result = await updateAuthenticate.executeMutation(loginForm);
      if (result.error) {
        errorMessage.value = result.error;
      } else {
        localStorage.setItem('authToken', result.data.authenticate.jwtToken);
        await router.push({ name: "home" });
      }
    } else {
      return false;
    }
  });
};

</script>

<style lang="scss" scoped>
.box-card {
  margin-bottom: 20px;
}

.el-form {
  margin-top: 20px;
}
</style>
