'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "cbf3eab25f88e9d3805c17788cac25a2",
"assets/AssetManifest.bin.json": "67f741c780a9380ece34ca6b07336d6e",
"assets/assets/fonts/anonymous-pro/AnonymousPro-Bold.ttf": "f5e69393343726e8479a8f5d77f50739",
"assets/assets/fonts/anonymous-pro/AnonymousPro-Regular.ttf": "1c0a292f3473dd6684c2cbee0f6ee5f3",
"assets/assets/fonts/fira-pro/static/FiraCode-Bold.ttf": "016bcf67f409675ff98373081ba753dd",
"assets/assets/fonts/fira-pro/static/FiraCode-Regular.ttf": "301dd380625eb548238ae3c39ec9f12b",
"assets/assets/fonts/helvetica/helvetica-neue-light.ttf": "0a4d37b22558e86fc49120e96fcc2d01",
"assets/assets/fonts/helvetica/helvetica-neue-medium.ttf": "bd96bc9a5d9c3b07b628529db257e176",
"assets/assets/fonts/helvetica/helvetica-neue-regular.ttf": "ea05f6114b3efb842e31b45781e087cf",
"assets/assets/fonts/jetbrains-mono/static/JetBrainsMono-Bold.ttf": "f855a5300fbbb56439586d4ca8a131b2",
"assets/assets/fonts/jetbrains-mono/static/JetBrainsMono-Regular.ttf": "b678c7a6800a9d944ae8342905c07cb7",
"assets/assets/fonts/pixelify/PixelifySans-Bold.ttf": "efc12ef1e774941865527ec2c0a3636c",
"assets/assets/fonts/pixelify/PixelifySans-Medium.ttf": "2081a0b1dd9a57d373839da37ef2bedd",
"assets/assets/fonts/pixelify/PixelifySans-Regular.ttf": "d6b4fe0a9425d5e9b459d654109498b4",
"assets/assets/fonts/pixelify/PixelifySans-SemiBold.ttf": "43dddc46855022399125a476c93a69cd",
"assets/assets/fonts/source-code-pro/static/SourceCodePro-Bold.ttf": "2ffe6059c12752d6c7c20cb5e8f78bea",
"assets/assets/fonts/source-code-pro/static/SourceCodePro-Regular.ttf": "d1f776b31a50ae68ace3819fdc58b065",
"assets/assets/fonts/ubuntu-mono/UbuntuMono-Bold.ttf": "d3e281ca75369e8517b3910bc46a7ed0",
"assets/assets/fonts/ubuntu-mono/UbuntuMono-Regular.ttf": "c8ca9c5cab2861cf95fc328900e6f1a3",
"assets/assets/icons/color-picker.png": "c4562944601e4deaa733c0980eb7a994",
"assets/assets/icons/ic_add_members.png": "e9531e765fb8e41ad0c813e55839f303",
"assets/assets/icons/ic_check.png": "6cdfa3cdb0fc158cd3b7fc0309d0e0db",
"assets/assets/icons/ic_github.png": "ec3a60c8c6539a07eb70b52f6737ea6e",
"assets/assets/icons/ic_google.png": "dc81337428308233cab399bdf883af12",
"assets/assets/icons/ic_incognito.png": "3a944696387b8408f035d190cf1bdde9",
"assets/assets/icons/ic_new_meeting.png": "06c1aab3aa874b40836bbb0620dd192c",
"assets/assets/icons/launcher_icon.png": "1ed52da05ffa9e309af70a9b71702810",
"assets/assets/icons/launcher_icon_android12.png": "c77b7cd0d8077193eefa01502b6bc191",
"assets/assets/images/background-1.jpg.webp": "c40d31c7892be5af05ff17f169704ef2",
"assets/assets/images/background-2.jpg.webp": "e99a327b4d1bb187658b4988e95c0446",
"assets/assets/images/background-3.jpg.webp": "822bb7ec9bae35212ab296220a85f4f3",
"assets/assets/images/background-4.jpg.webp": "a34c40aaecd9de2bf10b17120537f4cc",
"assets/assets/images/background-5.jpg.webp": "649147052cde49ff4328fda72540d794",
"assets/assets/images/background-6.jpg.webp": "8a1b5eff30f2b868a336b9c8f2c05c27",
"assets/assets/images/dash.gif": "8d1edeb2af6106c3666e22d9abcfb8a7",
"assets/assets/images/desktop-background-1.jpg.webp": "8a1b5eff30f2b868a336b9c8f2c05c27",
"assets/assets/images/desktop-background-2.jpg.webp": "82ac2d6b62fa760404b67eaca95a9476",
"assets/assets/images/desktop-background-3.jpg.webp": "2038a7ba0ddda31167e8f30cecb04895",
"assets/assets/images/desktop-background-4.jpg.webp": "0fea99ba24bf15d9bd2d68889ef376fc",
"assets/assets/images/desktop-background-5.jpg.webp": "0a8974488d35197850a14996b458e9a6",
"assets/assets/images/desktop-background-6.jpg.webp": "1c496537afe77cc2825c7c85af9977b9",
"assets/assets/images/desktop-background-7.jpg.webp": "9628b0065920e85b79e5718da6df106e",
"assets/assets/images/desktop-background-8.jpg.webp": "ffeaeb0843ff4dcabb37ff389cbf0bc6",
"assets/assets/images/desktop-background-9.jpg.webp": "ff93dab63878939bfd72fdc94c9dce06",
"assets/assets/images/img_app_logo.png": "167ed1eca18ef1f6f05988533fb25119",
"assets/assets/images/img_hello_message_1.gif": "22d4a6b08e6cdfcfd29bff082a177c2d",
"assets/assets/images/img_hello_message_2.gif": "3e99d0f7bf46f72df40b79117e753931",
"assets/assets/images/img_hello_message_3.gif": "ce25f2b98b2eed1329883302ffa9802f",
"assets/assets/images/img_hello_message_4.gif": "7fc03fceb1f62428f8fb5c5c302003c6",
"assets/assets/images/img_hello_message_5.gif": "fc6f81a9e5403c7715e66b5f784f9e47",
"assets/assets/images/img_hello_message_6.gif": "1af85dd0af2fe858e569445c1506fb41",
"assets/assets/images/img_hello_message_7.gif": "d57e024b8a197acebb1253a007fae491",
"assets/assets/images/img_logo.png": "60487b4970142ae7b45d079bf91966c1",
"assets/assets/images/logo_rounded.png": "17ff41070d710fd398378b8715ed5fe5",
"assets/assets/images/logo_rounded_2.png": "8d5f97aaf4b961ef30de578603d77d34",
"assets/assets/images/world-map.png": "f85466dc484d56b6a04115d169535af3",
"assets/assets/lotties/beauty-filters-lottie.json": "b76452af0cde1101ae7b7cb2da05a18b",
"assets/assets/lotties/broadcast-lottie.json": "926c9c116d6227d1943df855141d5188",
"assets/assets/lotties/request-zoom-out-lottie.json": "71aef842e5af8acf8a0802f8d5ea54dc",
"assets/assets/lotties/unlock-lottie.json": "d50824e33b800af50edc51bd29c6fed2",
"assets/assets/sounds/hand_raising.mp3": "c4e251e9d10667d5998346524bb24da4",
"assets/assets/sounds/joined.mp3": "ec9c1a40bfb665ba1295fe769b0c14df",
"assets/assets/sounds/leave.mp3": "2d794d83898ef23dcf3af03c1352975f",
"assets/assets/sounds/recording.mp3": "3984da678018c5a373a8a339e2a83fbe",
"assets/assets/welcome.java": "7e89c7746564993c1fda2187afb74586",
"assets/FontManifest.json": "6b0c0bcddbead084d3e93639aae90d90",
"assets/fonts/MaterialIcons-Regular.otf": "b5debfd19ab8c929aa82086110956f3d",
"assets/NOTICES": "7632bd32f9e1dad35378692a9ebe9a70",
"assets/packages/amplify_auth_cognito_dart/lib/src/workers/workers.min.js": "de4cf86bb47ae06dfe769b8d1ceaf0ec",
"assets/packages/amplify_auth_cognito_dart/lib/src/workers/workers.min.js.map": "d206bb2fe388804514ce79faaf0ed556",
"assets/packages/amplify_secure_storage_dart/lib/src/worker/workers.min.js": "86af2d874794fbbea3f1541926fdefdb",
"assets/packages/amplify_secure_storage_dart/lib/src/worker/workers.min.js.map": "bd2d9c0c33a0cf19270a74bcdbc2ddf9",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_image_compress_web/assets/pica.min.js": "5be3cefba23ccc901aeb5ef852d34063",
"assets/packages/iconsax_flutter/fonts/FlutterIconsax.ttf": "6ebc7bc5b74956596611c6774d8beb5b",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf": "8fedcf7067a22a2a320214168689b05c",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Duotone.ttf": "c48df336708c750389fa8d06ec830dab",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf": "5d304fa130484129be6bf4b79a675638",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Light.ttf": "f2dc1cd993671b155e3235044280ba47",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Thin.ttf": "f128e0009c7b98aba23cafe9c2a5eb06",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor.ttf": "003d691b53ee8fab57d5db497ddc54db",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
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
"CNAME": "22e138ff2999420ef1e17b352f694cdc",
"e2ee.worker.dart.js": "403a5c08e4376b23180169d189ca4062",
"e2ee.worker.dart.js.deps": "aed8376d40e82073393ae3b1a4083dd6",
"e2ee.worker.dart.js.map": "4e5c080598a536bada660879e15e7458",
"favicon.png": "1d2267187b24320362ad4c360bbf7d4f",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "96d2d74d08067ed53c10b183bb00ef24",
"icons/apple-touch-icon.png": "e98abdfac338801aac3e127563755a6a",
"icons/favicon.ico": "46faa5e24264f611ba9d26b89c69b184",
"icons/favicon.png": "1ed52da05ffa9e309af70a9b71702810",
"icons/Icon-192.png": "1ed52da05ffa9e309af70a9b71702810",
"icons/Icon-512.png": "1ed52da05ffa9e309af70a9b71702810",
"icons/Icon-maskable-192.png": "bba41cc5a249ef628e330e47adcbcf79",
"icons/Icon-maskable-512.png": "7175d335fef897f38223f627f72a89e6",
"index.html": "da897a764db4f1b921ea21b5865dd655",
"/": "da897a764db4f1b921ea21b5865dd655",
"main.dart.js": "42b1abe0736fd474489d600996142156",
"main.js": "2660012ca564ffb97e9ff0df09225f59",
"manifest.json": "de8111571a4e3d8dd6a6197dd6e5f188",
"splash/img/dark-1x.png": "a50fd6d5ceca3c75d30929f3cb71d0b2",
"splash/img/dark-2x.png": "f569b2413957712f279bd3f4727e6a64",
"splash/img/dark-3x.png": "f956766e59ed983d37200dc81a6e72d6",
"splash/img/dark-4x.png": "d93e1f50e4b19abbe0303532c3201705",
"splash/img/light-1x.png": "a50fd6d5ceca3c75d30929f3cb71d0b2",
"splash/img/light-2x.png": "f569b2413957712f279bd3f4727e6a64",
"splash/img/light-3x.png": "f956766e59ed983d37200dc81a6e72d6",
"splash/img/light-4x.png": "d93e1f50e4b19abbe0303532c3201705",
"version.json": "8f29752fcc08aa5e4b1b2249bb5e2274",
"virtual-background.js": "88763f051e72ead2382b4960023ae0f3"};
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
