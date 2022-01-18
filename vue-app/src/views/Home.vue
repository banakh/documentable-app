<template>
  <div v-if="fetchingGroup">
    Loading...
  </div>
  <div v-else-if="errorGroup">
    Oh no... {{ error }}
  </div>
  <div v-else>
    <el-button class="button-new-tag ml-1" size="" @click="showInput">
      + Add Group
    </el-button>
    <el-input
      v-if="inputVisible"
      ref="InputRef"
      v-model="inputValue"
      @keyup.enter="handleInputConfirm"
      @blur="handleInputConfirm"
    >
    </el-input>
    <el-menu
      class="el-menu-demo"
      mode="horizontal"
      v-else
      :router="true"
    >
      <el-menu-item :route="{ name: 'folder', params: { groupId: item.groupByGroupId.id }}"
                    :index="item.groupByGroupId.id" v-for="item in dataGroup.allMemberships.nodes" :key="item.groupId">
        {{ item.groupByGroupId.name }}
      </el-menu-item>
    </el-menu>

  </div>
  <router-view :key="$route.fullPath"></router-view>
</template>

<script setup>
import { ref, nextTick } from "vue";
// import { ElMessageBox } from 'element-plus'
import { useMutation, useQuery } from "@urql/vue";

const getGroup = `query userGroups {
  allMemberships {
    nodes {
      groupByGroupId {
        id
        name
      }
    }
  }
}
`;
const createGroup = `mutation createGroup($userId: UUID!, $groupName: String!) {
  addGroup(input: {userId: $userId, name: $groupName}) {
    results {
      groupId
      groupName
    }
  }
}`;

const inputValue = ref("");
const inputVisible = ref(false);
const InputRef = ref();

// const handleClose = () => {
// };
//
// const onChange = (status,group) => {
//   console.log('---');
//   group.active = status
// }

const showInput = () => {
  inputVisible.value = true;
  nextTick(() => {
    InputRef.value?.input?.focus();
  });
};

const updateGroup = useMutation(createGroup);

const groupResult = useQuery({
  query: getGroup
});
const fetchingGroup = groupResult.fetching;
const dataGroup = groupResult.data;
const errorGroup = groupResult.error;


const handleInputConfirm = async () => {
  if (inputValue.value) {
    await updateGroup.executeMutation({
      groupName: inputValue.value,
      userId: "d9baed9a-5bba-4a8f-9c6a-e348a1f6f3c7"
    });
    groupResult.executeQuery({
      requestPolicy: "network-only"
    });
  }
  inputVisible.value = false;
  inputValue.value = "";
};

</script>

<style scoped>
.el-input {
  width: 100px;
}

.el-tag {
  margin-right: 15px;
}
</style>
