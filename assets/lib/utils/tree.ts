export interface TreeNode {
  name: string;
  path: string;
  children?: TreeNode[];
}

export const addRoot = (name: string, tree: TreeNode[]): TreeNode[] => {
  return [
    {
      name,
      path: "/",
      children: tree,
    },
  ];
};

export const buildTree = (paths: string[]): TreeNode[] => {
  return paths
    .map((path) => path.split("/"))
    .reduce(
      (acc: TreeNode[], pathParts) => buildTreeHelper(acc, pathParts, ""),
      [],
    );
};

const buildTreeHelper = (
  acc: TreeNode[],
  pathParts: string[],
  currentPath: string,
): TreeNode[] => {
  const [name, ...rest] = pathParts;

  const existingIndex = acc.findIndex((node) => node.name === name);

  if (rest.length === 0) {
    return existingIndex === -1
      ? [...acc, { name, path: join(currentPath, name) }]
      : acc;
  }

  if (existingIndex === -1) {
    return [
      ...acc,
      {
        name,
        children: buildTreeHelper([], rest, join(currentPath, name)),
        path: join(currentPath, name),
      },
    ];
  }

  return acc.map((node, index) => {
    if (index !== existingIndex) {
      return node;
    }

    return {
      ...node,
      children: buildTreeHelper(
        node.children || [],
        rest,
        join(currentPath, name),
      ),
    };
  });
};

const join = (left: string, right: string) => {
  const paths = [left, right];
  return paths
    .map((path) => path.replace(/^\/+|\/+$/g, ""))
    .filter(Boolean)
    .join("/");
};
