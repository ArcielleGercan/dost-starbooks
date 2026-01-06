'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "f5004187991a42cb518cd7204376899f",
"assets/AssetManifest.bin.json": "8437ad84ceb6538eef8f73ff188875a2",
"assets/assets/audio/battle.mp3": "a9940abfad8bf91f2afcabd93be96564",
"assets/assets/audio/click1.wav": "fe3cf20a961c12fa92c76ea0687a3b39",
"assets/assets/audio/dialouge.mp3": "fdd3e2db5390f969e8df188d58913ad9",
"assets/assets/audio/homepage_music.mp3": "5ceab34f18b0ee5bbd5be9caba6a5bbc",
"assets/assets/audio/matchpuzzle.mp3": "75104785389d696adb5bfdf5e1dfb95e",
"assets/assets/audio/quiz_music.mp3": "2440a8152cf8a15e21aad34d0a0807aa",
"assets/assets/backgrounds/averagebg.png": "61763c3e8865244165c87009e52d21b4",
"assets/assets/backgrounds/difficultbg.png": "32268bff20da3fd655a29626b6007afc",
"assets/assets/backgrounds/easybg.png": "6191874d58ff3346e681711137124b7c",
"assets/assets/backgrounds/sslogo.jpeg": "f7cd2d16eac0064cc5481350020b72da",
"assets/assets/fonts/Poppins-Bold.ttf": "5db3d2b3980827dae28161da22b1753a",
"assets/assets/fonts/Poppins-Regular.ttf": "29cc97af5403e3251cbb586727938473",
"assets/assets/images-avatars/Adventurer.png": "53297479a9b15a0eb309c7eea68762f6",
"assets/assets/images-avatars/Astronaut.png": "626559bbc2f3662d9425023ad3f850bb",
"assets/assets/images-avatars/Boy.png": "6c1fe73b7eecfbd9b47bc2d3c51c4ea0",
"assets/assets/images-avatars/Brainy.png": "105268c0eb7d07c9f1f4e18f0c23155b",
"assets/assets/images-avatars/Cool-Monkey.png": "2152b0f91d84ae43a19f30e84e6a3374",
"assets/assets/images-avatars/Cute-Elephant.png": "2e7d218ca7f2ecbcfdee0613984446b2",
"assets/assets/images-avatars/Doctor-Boy.png": "89912ff752a64f78a6eb4b6ec0d696bb",
"assets/assets/images-avatars/Doctor-Girl.png": "deb87a5a729a8d90fef0ac659a5a2fd8",
"assets/assets/images-avatars/Engineer-Boy.png": "32364c7df4a1b8aeaae1739a8ba6804a",
"assets/assets/images-avatars/Engineer-Girl.png": "996c15451c8804e64058e313de35d214",
"assets/assets/images-avatars/Girl.png": "ff81990710163aa3a61d001092be56e1",
"assets/assets/images-avatars/Hacker.png": "0b6f34a1c78ab414aee0faa617c24cbc",
"assets/assets/images-avatars/Leonel.png": "bd5abf79e0fb77a3bf6328b16bab5bc5",
"assets/assets/images-avatars/Scientist-Boy.png": "e69f505a515440b4c925ac831153e9a2",
"assets/assets/images-avatars/Scientist-Girl.png": "c50e9cc1df303e3d3f9d22105070f161",
"assets/assets/images-avatars/Sly-Fox.png": "15f74233e68d480bfc9ce2ba259b5e6b",
"assets/assets/images-avatars/Sneaky-Snake.png": "0f7be84eedee2992d9b170ad0bfd946d",
"assets/assets/images-avatars/Teacher-Boy.png": "acf942559191419d729a8efc0c6cc91c",
"assets/assets/images-avatars/Teacher-Girl.png": "097244a058a488813706cde005bbc40d",
"assets/assets/images-avatars/Twirky.png": "460116e336e3ce168ee4a876afe4545b",
"assets/assets/images-avatars/Whiz-Achiever.png": "c948805dae03365aa5650cfc64a07d74",
"assets/assets/images-avatars/Whiz-Busy.png": "066df238b2de2c2e7ea12493c23c8afa",
"assets/assets/images-avatars/Whiz-Happy.png": "c3b5c72cb5520cfd0c6d8aba74c7d44b",
"assets/assets/images-avatars/Whiz-Ready.png": "8c6d2c7d02386f421e6e20f7c907e2f2",
"assets/assets/images-avatars/Wise-Turtle.png": "253a446bbc7bf2eaf7eaad818694d516",
"assets/assets/images-badges/whiz-achiever.png": "c948805dae03365aa5650cfc64a07d74",
"assets/assets/images-badges/whiz-happy.png": "c3b5c72cb5520cfd0c6d8aba74c7d44b",
"assets/assets/images-badges/whiz-ready.png": "8c6d2c7d02386f421e6e20f7c907e2f2",
"assets/assets/images-icons/background1.png": "e2b859083d0f37525f5b4935a67c7681",
"assets/assets/images-icons/lightbulb.png": "809620e3b0eb92bde8e0b19ebccb266f",
"assets/assets/images-icons/math.png": "362567befdc27a53e65d500889c03233",
"assets/assets/images-icons/placeholder.png": "77a86575d0f004b818f60d2952b070d4",
"assets/assets/images-icons/sadlogout.png": "a6ab75f32c3396281eb84520a87a1e0c",
"assets/assets/images-icons/science.png": "d9da48b79b4446fe228903183c64ab6f",
"assets/assets/images-logo/bird1.png": "324cd7cf0312b6a6b3b37ebd085523a3",
"assets/assets/images-logo/bird2.png": "d59b97336cccd2a3b60909f2c1f323b5",
"assets/assets/images-logo/starbookslogin.png": "21148b9a802cef9831d030448dd9f264",
"assets/assets/images-logo/starbooksmainlogo.png": "2bfdc8d326fa341ebb56d3c7ea3c6e65",
"assets/assets/images-logo/starbooksmainlogo150.png": "5eaeef42e7270278b30fbde22c5145b7",
"assets/assets/images-logo/starbooksnewlogo.png": "cd09e506ec582d2300b06d66134db635",
"assets/assets/images-logo/success.png": "447251cc30622af43f53d8974a3c093f",
"assets/assets/images-logo/whizbattle.png": "abd68b13177a89a1e28afe40e51eeaff",
"assets/assets/images-logo/whizchallenge.png": "22cd3e1d2a0118d082807c37ef41d9f1",
"assets/assets/images-logo/whizmemorymatch.png": "6a676e53a355974d4c218e86a3be8b09",
"assets/assets/images-logo/whizpuzzle.png": "4891fd03b4a45fc29f28506b749843cf",
"assets/assets/memorymatch/average.png": "0274f845e7b8684aa2f0b76c089c78ca",
"assets/assets/memorymatch/average1.png": "4785536b4e23d7a4521fa97ed575b9b0",
"assets/assets/memorymatch/average2.png": "66bc7dc0cb6e0c707c0faf78eab5b45e",
"assets/assets/memorymatch/average3.png": "53d41de99b7c3b8efefbd0a16422a775",
"assets/assets/memorymatch/average4.png": "f7d94a808f6c482a94561b45ec9f4956",
"assets/assets/memorymatch/average5.png": "dfb73fd306b64beab61012dbd0d31571",
"assets/assets/memorymatch/average6.png": "d938a40fbe673ec20ca2c7a710b8946c",
"assets/assets/memorymatch/difficult.png": "bfbe01a6611b6035425bca089db5350c",
"assets/assets/memorymatch/difficult1.png": "d0707e05a16b70975c5f5bfa535b8e7c",
"assets/assets/memorymatch/difficult2.png": "c8939a6ec8998e7e4bda8113df05ed7f",
"assets/assets/memorymatch/difficult3.png": "dd55f9577212ee5c677241eb56dc4ba6",
"assets/assets/memorymatch/difficult4.png": "5b70071757889e4fddc50723f7e7112a",
"assets/assets/memorymatch/difficult5.png": "f2d3a422dad2fbb3fd141664fe082222",
"assets/assets/memorymatch/difficult6.png": "a15c6599e8548a9cf08868c6f83aa18f",
"assets/assets/memorymatch/difficult7.png": "5afd4894e182448cc878092d754f348e",
"assets/assets/memorymatch/easy.png": "55952f74895e497d8a71f38f67a67ae7",
"assets/assets/memorymatch/easy1.png": "8e46ce23bc95f6e15976cfaece88420b",
"assets/assets/memorymatch/easy2.png": "b503439bd3f7068d9f05fe7d2776f7f9",
"assets/assets/memorymatch/easy3.png": "3ef69bb931b67c91cebf96bc2a03713d",
"assets/assets/memorymatch/easy4.png": "b13a605da34d8b33a2924b8a798bc2e1",
"assets/assets/memorymatch/easy5.png": "49e25fd3d81b4eec47939595952ca695",
"assets/assets/puzzle/animals.jpg": "875cb4c68ce8cfc51facff75df0ec0ca",
"assets/assets/puzzle/geometry.jpg": "548e4bfbb74c6e42d0c300082475bb7d",
"assets/assets/puzzle/human_body.png": "7153dc63cef48e2e159a006c6fef2ee8",
"assets/assets/puzzle/scientists.jpg": "639c2361f2f2ba12f095e67f342a5604",
"assets/assets/puzzle/solar_system.png": "039736a630a938894cea101f7a299d27",
"assets/assets/puzzle/starbookswhiz.jpeg": "2dd2b1832415a218adcf26353940f705",
"assets/FontManifest.json": "13f2d5a1592b9371295a772e8dddea78",
"assets/fonts/MaterialIcons-Regular.otf": "3b2a2cdcf432472679592d027cf893cf",
"assets/NOTICES": "1a0c07317b844f69b0e2de98a38f4dcb",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "109dfba5d9ece2cc40ce3732b9e0abec",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "84ba04245db81623716aba6896c74fb6",
"/": "84ba04245db81623716aba6896c74fb6",
"main.dart.js": "64a8a9be92dd01cf59944fa1a37c7a9f",
"manifest.json": "a803486396f81fd670bb3143ec42ba78",
"starbooksnewlogo.png": "00e70c5701004745f4702171cdb8e7af",
"version.json": "b15ede7573cd8a8c47d8d1d14586050a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
