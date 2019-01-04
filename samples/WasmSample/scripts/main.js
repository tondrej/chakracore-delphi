const DIMENSIONS = 50;
const verbose = false; // true;

const rand = () => Math.floor(Math.random() * DIMENSIONS);

WebAssembly.instantiate(loadWasm('main.wasm'), {
  console: {
    log: (x, y) => console.log(x, y)
  }
}).then(results => {
  const game = results.instance.exports;

  for (let i = 0; i < 400; i++) {
    game.setCell(rand(), rand(), 1);
  }

  let step = 0;

  const render = () => {
	let count = 0;
    ctx.fillStyle = "black";
    ctx.fillRect(0, 0, DIMENSIONS, DIMENSIONS);

    ctx.fillStyle = "green";
    for (let y = 0; y < DIMENSIONS; y++) {
      for (let x = 0; x < DIMENSIONS; x++) {
        if (game.getCell(x, y) > 0) {
          ctx.fillRect(x, y, 1, 1);
		  count++;
        }
      }
    }
	
    if (verbose) {
	  console.log('Step %d: %d alive', step++, count);
	}
  };

  setInterval(() => {
    game.tick();
    render();
  }, 50);

});