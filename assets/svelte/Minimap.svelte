<script lang="ts">
  import { onMount } from "svelte";

  type Config = {
    [className: string]: {
      alpha: number;
      fillStyle: CanvasFillStrokeStyles["fillStyle"];
    };
  };

  export let root: HTMLElement;
  export let config: Config;

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

    Object.entries(config).forEach(([className, { fillStyle, alpha }]) => {
      for (const element of root.getElementsByClassName(className)) {
        const elementRect = element.getBoundingClientRect();

        canvasContext.fillStyle = fillStyle;
        canvasContext.globalAlpha = alpha;
        canvasContext.fillRect(
          0,
          elementRect.y - rootRect.y + root.scrollTop,
          root.clientWidth,
          elementRect.height,
        );
      }
    });

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
