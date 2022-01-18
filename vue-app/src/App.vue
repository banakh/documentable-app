<template>
  <el-container>
    <el-header>Header</el-header>
    <el-main>
      <div class="main-content">
        <div class="content">
          <router-view></router-view>
        </div>
      </div>
    </el-main>
<!--    <el-footer>-->
<!--      © Documentable App , 2022-->
<!--    </el-footer>-->
  </el-container>
</template>

<script setup>
import { useQuery } from "@urql/vue";
import {useStore} from "vuex";
const store = useStore()
const fetchCurrentUser = async () => {
  const result = await useQuery({
    query: `query getPerson {
  currentPerson {
    username
    id
  }
}`
  });
  store.commit("auth/setCurrentUser", result.data.value.currentPerson);
};

fetchCurrentUser();


</script>

<style lang="scss" scoped>
@media only screen and (max-width: 768px) {
  .content {
    padding: 0 !important;
  }
}

.el-container {
  height: 100vh;
}

.el-header{
  border-bottom: 1px solid #ebeef4;
}
.content {
  padding: 16px;
  height: 100%;
}
.el-main{
  padding: 0;
}
.el-footer{
  color: #8e8e8e;
  text-align: center;
  font-size: 12px;
  height: 40px;
}

.main-content {
  max-width: 1150px;
  margin: 0 auto;
  flex: 1 0 auto;
  width: 100%;
}
</style>
