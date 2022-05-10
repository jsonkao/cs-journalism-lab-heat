<script context="module">
	import { feature } from 'topojson-client';
	import { base } from '$app/paths';

	export async function load({ fetch }) {
		// Fetch TopoJSON data; do necessary transformations
		const censusData = await (await fetch(`${base}/census.topojson`)).json();
		const census = feature(censusData, censusData.objects.census);

		return {
			props: {
				census
			}
		};
	}
</script>

<script>
	import { onMount } from 'svelte';

	export let census;

	let map, loaded;
	let year = 'temp_past';
	let metric = 'imp';

	export function hexToRGB(hex) {
		if (!hex.startsWith('#')) {
			return hex;
		}
		let r = parseInt(hex.slice(1, 3), 16);
		let g = parseInt(hex.slice(3, 5), 16);
		let b = parseInt(hex.slice(5, 7), 16);
		if (hex.length > 7) {
			return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + parseInt(hex.slice(7, 9), 16) / 255 + ')';
		} else {
			return 'rgb(' + r + ', ' + g + ', ' + b + ')';
		}
	}

	function color({ properties: d }) {
		if (!d[year]) return 'rgba(0, 0, 0, 0)';
		const colors = [
			'#22e4e5',
			'#67ecec',
			'#aef4f3',
			'#f3f3af',
			'#eded66',
			'#e5e521',
			'#2fb0e6',
			'#6ab0ed',
			'#b2b0f4',
			'#f4afb1',
			'#edaf6a',
			'#e7b02a',
			'#386ae7',
			'#6f69ed',
			'#b368ec',
			'#ed67b1',
			'#ee686c',
			'#e96932',
			'#3b2de5',
			'#702be5',
			'#b427e6',
			'#e525b2',
			'#e6286c',
			'#e72934'
		].map(hexToRGB);
		const cutoffs = {
			temp_past: [
				75.51255834164694, 78.14788023885677, 79.9428946835466, 81.62303270656426,
				83.41042267761047, 93.93799025498207
			],
			temp: [
				79.2023181629553, 81.75172738815884, 83.55452214893113, 85.18752825955092,
				86.95933244727853, 96.51681672713941
			],
			tree: [0.04278385197645081, 0.14645235069885643, 0.35050369685767097, 0.8286626506024096],
			income: [49896.0, 78194.0, 120580.0, 250001.0],
			imp: [127.6, 1163.8500000000029, 2705.380000000008, 8296.239999999852],
			imp: [6.4, 10.6, 14, 8297],
			imp: [6.4, 14, 200, 8297],
			// builtfar: [2.385, 8.4, 30.71, 71.67],
			builtfar: [0.49, 0.7, 1.7, 71.67],
			residfar: [0.5, 1, 2.5, 10]
		};
		let y, m;
		for (y = 0; y < cutoffs[year].length; y++) {
			if (d[year] <= cutoffs[year][y]) break;
		}
		if (metric === 'None') {
			m = 0;
		} else {
			for (m = 0; m < cutoffs[metric].length; m++) {
				if (d[metric] <= cutoffs[metric][m]) break;
			}
		}
		return colors[Math.min(y + m * 6, 23)];
	}

	function getCensusFills() {
		const matchExp = ['match', ['get', 'GEOID']];
		census.features.forEach((f) => {
			matchExp.push(f.properties.GEOID, color(f));
		});
		matchExp.push('rgba(0, 0, 0, 0)');
		return matchExp;
	}

	onMount(() => {
		console.log(census.features[0]);
		mapboxgl.accessToken =
			'pk.eyJ1IjoianNvbmthbyIsImEiOiJjanNvM2U4bXQwN2I3NDRydXQ3Z2kwbWQwIn0.JWAoBlcpDJwkzG-O5_r0ZA';
		map = new mapboxgl.Map({
			container: 'map',
			style: 'mapbox://styles/jsonkao/ckvnu5tpy6coj14uizvyf1wuf/draft',
			center: [-73.967, 40.72],
			zoom: 11
		});

		map.on('load', async () => {
			map.addSource('census', { type: 'geojson', data: census });
			map.addLayer(
				{
					id: 'census',
					type: 'fill',
					source: 'census',
					paint: {
						'fill-color': getCensusFills()
					}
				},
				'parks'
			);
			loaded = true;
		});
	});

	$: {
		if (loaded) {
			map.setPaintProperty('census', 'fill-color', getCensusFills(year, metric));
		}
	}

	// saturation --> temperature
	// connecting it to areas we are able to investigate next
	// writeup with images: what u did, why, the workflow, how it could be useful to journalists, and next steps. doesn't have to be long — get to the damn point. bullet points and images.  at least a draft of that stuff
</script>

<svelte:head>
	<title>Urban Heat</title>
	<link href="https://api.mapbox.com/mapbox-gl-js/v2.5.1/mapbox-gl.css" rel="stylesheet" />
	<script src="https://api.mapbox.com/mapbox-gl-js/v2.5.1/mapbox-gl.js"></script>
</svelte:head>

<div class="container">
	<div class="controls">
		<select bind:value={year}>
			{#each ['temp', 'temp_past'] as y}
				<option value={y}>{{ temp: '2018 Temp', temp_past: '2000 Temp' }[y]}</option>
			{/each}
		</select>
		<select bind:value={metric}>
			{#each ['None', 'tree', 'income', 'imp', 'builtfar', 'residfar'] as m}
				<option value={m}
					>{{ imp: 'Impervious surfacing', builtfar: 'Building FAR', residfar: 'Residential FAR' }[
						m
					] || m}</option
				>
			{/each}
		</select>

		{#if metric !== 'None'}
			<div id="legend-container">
				<div id="x-axis-labels" style="height: 210px">
					<p class="halo">Hotter</p>
					<p class="halo">Colder</p>
				</div>
				<div id="x-axis" style="height: 240px; width: 16px;">
					<svg viewBox="-8 0 16 240">
						<defs>
							<marker
								id="arrowhead"
								markerWidth="10"
								markerHeight="6"
								refX="0"
								refY="3"
								orient="auto"
							>
								<polygon points="0 0, 6 3, 0 6" />
							</marker>
						</defs>
						<line x1="0" y1="120" x2="0" y2="16" marker-end="url(#arrowhead)" />
						<line x1="0" y1="120" x2="0" y2="224" marker-end="url(#arrowhead)" />
					</svg>
				</div>
				<div id="legend">
					<div
						id="legend-temp"
						style="position: absolute;
				width: 100%;
				height: 100%;
				mix-blend-mode: darken;background: linear-gradient(0deg, rgb(34, 229, 229) 0%, rgb(34, 229, 229) 16.6667%, rgb(102, 236, 236) 16.6667%, rgb(102, 236, 236) 33.3333%, rgb(174, 243, 243) 33.3333%, rgb(174, 243, 243) 50%, rgb(243, 243, 174) 50%, rgb(243, 243, 174) 66.6667%, rgb(236, 236, 102) 66.6667%, rgb(236, 236, 102) 83.3333%, rgb(229, 229, 34) 83.3333%, rgb(229, 229, 34) 100%);"
					>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
						<div style="height: 30px;">
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
							<div style="width: 30px; height: 30px;" class="" />
						</div>
					</div>
					<div
						id="legend-imp"
						style="background: linear-gradient(90deg, rgb(250, 250, 250) 0%, rgb(250, 250, 250) 25%, rgb(243, 174, 243) 25%, rgb(243, 174, 243) 50%, rgb(236, 102, 236) 50%, rgb(236, 102, 236) 75%, rgb(229, 34, 229) 75%, rgb(229, 34, 229) 100%);"
					/>
				</div>
				<div id="y-axis" class="visible" style="color: #d73027;">
					<svg viewBox="0 0 160 16">
						<defs>
							<marker
								id="arrowhead"
								markerWidth="10"
								markerHeight="6"
								refX="0"
								refY="3"
								orient="auto"
							>
								<polygon points="0 0, 6 3, 0 6" />
							</marker>
						</defs>
						<line x1="0" y1="8" x2="151" y2="8" marker-end="url(#arrowhead)" />
					</svg>
				</div>
				<div id="y-axis-label"><p class="halo">{metric}</p></div>
			</div>
		{/if}
	</div>
	<div id="map" />
</div>

<style>
	:global(body) {
		overflow: hidden;
	}

	.container {
		margin: 0 auto;
		font-size: var(--container-font);
	}

	select {
		font-size: 1em;
		outline: none;
		padding: 3px;
		margin-bottom: 5px;
	}

	.controls {
		position: fixed;
		max-width: var(--control-width);
		top: 22px;
		left: 22px;
		padding: 15px;
		z-index: 1;
		/* background: #fff;
		box-shadow: 0px 2px 5px #0006; */
	}

	#map {
		width: 100vw;
		height: 100vh;
	}

	#legend-container {
		padding: 6px;
		display: grid;
		grid-template-columns: repeat(3, auto);
		grid-template-rows: repeat(3, auto);
	}

	#x-axis-labels {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		align-self: center;
	}

	#x-axis-labels p {
		padding: 0;
		text-align: right;
	}

	#x-axis {
		margin-right: 9px;
	}

	#y-axis {
		grid-column: 3;
		grid-row: 2;
		margin-top: 9px;
		transition-duration: 0.3s;
	}

	#y-axis-label {
		grid-column: 3;
		grid-row: 3;
		transition-duration: 0.3s;
	}
	#legend-temp {
		box-shadow: 0 4px 12px 0 rgba(0, 0, 0, 0.5);
		display: flex;
		flex-direction: column-reverse;
	}

	#legend-temp > div > div {
		display: inline-block;
		box-sizing: border-box;
	}

	#legend > div {
		position: absolute;
		width: 100%;
		height: 100%;
		mix-blend-mode: darken;
	}

	#legend {
		width: 160px;
		height: 240px;
		position: relative;
	}

	line {
		stroke-width: 1.5px;
		stroke: #121212;
	}
</style>
