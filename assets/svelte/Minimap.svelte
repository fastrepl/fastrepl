<script lang="ts">
  import { onMount } from "svelte";

  export let root: HTMLElement;

  let canvas: HTMLCanvasElement;
  let canvasContext: CanvasRenderingContext2D;

  let timeout: ReturnType<typeof setTimeout>;

  onMount(() => {
    canvasContext = canvas.getContext("2d");
    setTimeout(reRender, 100);

    const handleScroll = () => {
      showCanvas();
      reRender();
    };

    root.addEventListener("scroll", handleScroll);
    return () => {
      root.removeEventListener("scroll", handleScroll);
    };
  });

  const showCanvas = () => {
    canvas.style.visibility = "visible";
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      canvas.style.visibility = "hidden";
    }, 1000);
  };

  const reRender = () => {
    if (!canvasContext || !root) {
      return;
    }
    canvas.width = 20;
    canvas.height = 240;

    canvasContext.setTransform(1, 0, 0, 1, 0, 0);

    const canvasBounds = canvas.getBoundingClientRect();
    canvasContext.scale(
      canvasBounds.width / root.scrollWidth,
      canvasBounds.height / root.scrollHeight,
    );

    canvasContext.clearRect(0, 0, root.scrollWidth, root.scrollHeight);

    const rootRect = root.getBoundingClientRect();

    for (const element of root.getElementsByClassName("line-background")) {
      const elementRect = element.getBoundingClientRect();

      canvasContext.fillStyle = "rgb(253 224 71)";
      canvasContext.globalAlpha = 0.8;
      canvasContext.fillRect(
        0,
        elementRect.y - rootRect.y + root.scrollTop,
        elementRect.width,
        elementRect.height,
      );
    }

    canvasContext.fillStyle = "gray";
    canvasContext.globalAlpha = 0.2;
    canvasContext.fillRect(
      0,
      root.scrollTop,
      root.clientWidth,
      root.clientHeight,
    );
  };
</script>

<canvas
  bind:this={canvas}
  style="visibility: hidden;"
  class="px-0.5 border border-gray-200 rounded-md"
/>
