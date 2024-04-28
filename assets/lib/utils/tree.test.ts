import { expect, test } from "vitest";

import { buildTree } from "./tree";

test("empty", () => {
  expect(buildTree([])).toEqual([]);
});

test("flat", () => {
  const paths = ["a.py", "b.py", "c.py"];
  expect(buildTree(paths)).toEqual([
    {
      name: "a.py",
      path: "a.py",
    },
    {
      name: "b.py",
      path: "b.py",
    },
    {
      name: "c.py",
      path: "c.py",
    },
  ]);
});

test("nested, simple", () => {
  const paths = ["src/a.py", "src/b.py", "src/c/d.py"];
  expect(buildTree(paths)).toEqual([
    {
      name: "src",
      path: "src",
      children: [
        {
          name: "a.py",
          path: "src/a.py",
        },
        {
          name: "b.py",
          path: "src/b.py",
        },
        {
          name: "c",
          path: "src/c",
          children: [
            {
              name: "d.py",
              path: "src/c/d.py",
            },
          ],
        },
      ],
    },
  ]);
});

test("nested, complex", () => {
  const paths = [
    "src/folder/a.py",
    "src/folder/b.py",
    "src/folder/c/d.py",
    "src/folder/c/e.py",
  ];
  expect(buildTree(paths)).toEqual([
    {
      name: "src",
      path: "src",
      children: [
        {
          name: "folder",
          path: "src/folder",
          children: [
            {
              name: "a.py",
              path: "src/folder/a.py",
            },
            {
              name: "b.py",
              path: "src/folder/b.py",
            },
            {
              name: "c",
              path: "src/folder/c",
              children: [
                {
                  name: "d.py",
                  path: "src/folder/c/d.py",
                },
                {
                  name: "e.py",
                  path: "src/folder/c/e.py",
                },
              ],
            },
          ],
        },
      ],
    },
  ]);
});
