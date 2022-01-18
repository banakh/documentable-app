<template>
  <el-card class="box-card">
    <el-form ref="refRegisterForm" :model="registerForm" :rules="rules">
      <el-form-item prop="username">
        <el-input
          type="text"
          placeholder="Username"
          id="username"
          name="username"
          v-model="registerForm.username"
        ></el-input>
      </el-form-item>
      <el-form-item prop="password">
        <el-input
          placeholder="Password"
          type="password"
          v-model="registerForm.password"
        ></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="submitForm">Register</el-button>
      </el-form-item>
    </el-form>
    <el-alert
      v-if="errorMessage"
      :title="errorMessage"
      type="error"
      show-icon
    >
    </el-alert>
  </el-card>
  <el-card>
    <div style="font-size: 14px">
      Have an account?
      <router-link to="/login" custom v-slot="{ href, navigate }">
        <el-button :href="href" @click="navigate" type="text">
          Log in
        </el-button>
      </router-link>
    </div>
  </el-card>
</template>

<script setup>
import { ref, reactive } from "vue";
import { useRouter } from "vue-router";
import { useMutation } from "@urql/vue";
import { ElNotification } from 'element-plus'



const errorMessage = ref("");
const refRegisterForm = ref(null);
const router = useRouter();
const registerForm = reactive({
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
  password: [
    {
      min: 6,
      trigger: "blur",
      message: "Set Minimum password length to at least a value of 6"
    }
  ]
};
const registerMutation = `
  mutation register($username: String!, $password: String!) {
  register(input: {username: $username, password: $password}) {
    user {
      id
    }
  }
}
`;
const updateRegister = useMutation(registerMutation);

function submitForm() {
  refRegisterForm.value.validate(async (valid) => {
    if (valid) {
      const result = await updateRegister.executeMutation(registerForm);
      if (result.error) {
        errorMessage.value = result.error;
      } else {
        ElNotification.success({
          title: "Success",
          duration: 10000,
          icon: "el-icon-message",
          message: "Thank you, you have just been registered."
        });
        await router.push({ name: "login" });
      }
    } else {
      return false;
    }
  });
}

</script>

<style lang="scss" scoped>
.box-card {
  margin-bottom: 20px;
}

.el-form {
  margin-top: 20px
}
</style>
