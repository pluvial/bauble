(defn id [x] x)

(defn clamp [x lo hi]
  (cond
    (< x lo) lo
    (> x hi) hi
    x))

(defn math/sign [x]
  (cond
    (< x 0) -1
    (> x 0) 1
    0))

(def pi math/pi)
(def tau/2 pi)
(def tau (* 2 tau/2))
(def tau/360 (/ pi 180))

(defn- make-ratio [x y]
  ~(def ,(symbol (string x "/" y)) (/ ,x ,y)))

(eval ~(upscope ,;(map |(make-ratio 'pi $) (range 2 13))))
(eval ~(upscope ,;(map |(make-ratio 'tau $) (range 3 13))))

(defn deg [x] (* tau/360 x))
(defn tau* [x] (* tau x))
(defn tau/ [x] (/ tau x))
(defn pi* [x] (* pi x))
(defn pi/ [x] (/ pi x))

(defn axis-vec [axis scale]
  (case axis
    :x [scale 0 0]
    :y [0 scale 0]
    :z [0 0 scale]
    :+x [scale 0 0]
    :+y [0 scale 0]
    :+z [0 0 scale]
    :-x [(- scale) 0 0]
    :-y [0 (- scale) 0]
    :-z [0 0 (- scale)]
    (error "unknown axis")))

(defn rgb [r g b]
  [(/ r 255) (/ g 255) (/ b 255)])

(defn hsv [h s v]
  (def h (mod h 1))
  (def s (clamp s 0 1))
  (def v (clamp v 0 1))

  (def m (* v (- 1 s)))
  (def z (* (- v m) (- 1 (math/abs (- (mod (* h 6) 2) 1)))))
  (def h- (* h 6))
  (cond
    (< h- 1) [v (+ z m) m]
    (< h- 2) [(+ z m) v m]
    (< h- 3) [m v (+ z m)]
    (< h- 4) [m (+ z m) v]
    (< h- 5) [(+ z m) m v]
             [v m (+ z m)]))

(defn hsv-deg [h s v] (hsv (/ h 360) s v))

(defn hsl [h s l]
  (def h (mod h 1))
  (def s (clamp s 0 1))
  (def l (clamp l 0 1))

  (def c (* s (- 1 (math/abs (- (* 2 l) 1)))))
  (def h- (* 6 h))
  (def x (* c (- 1 (math/abs (- (mod h- 2) 1)))))

  (def [r g b]
    (cond
      (< h- 1) [c x 0]
      (< h- 2) [x c 0]
      (< h- 3) [0 c x]
      (< h- 4) [0 x c]
      (< h- 5) [x 0 c]
               [c 0 x]))

  (def m (- l (* 0.5 c)))
  [(+ r m) (+ g m) (+ b m)])

(defn hsl-deg [h s l] (hsl (/ h 360) s l))

(defn hex-rgb [hex]
  (let [r (-> hex (band 0xff0000) (brshift 16))
        g (-> hex (band 0x00ff00) (brshift 8))
        b (-> hex (band 0x0000ff))]
    (rgb r g b)))

(defn- fork-helper [initial args]
  (var expecting-join false)
  (var join nil)
  (var shape nil)
  (def fs (if initial @[id] @[]))
  (each arg args
    (if expecting-join
      (do
        (set expecting-join false)
        (set join arg))
      (if (= arg :join)
        (do
          (unless (nil? join)
            (error "join specified multiple times"))
          (set expecting-join true))
        (if (nil? shape)
          (set shape arg)
          (array/push fs arg)))))

  (default join '(union))
  (default shape (error "must specify an initial shape"))

  (let [$shape (gensym)
        join (if (tuple? join) join [join])
        transformed (map (fn [f] ~(-> ,$shape ,f)) fs)]
    ~(let [,$shape ,shape]
      (,;join ,;transformed))))

(defmacro fork [& args]
  (fork-helper false args))

(defmacro spoon [& args]
  (fork-helper true args))
