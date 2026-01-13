require 'sinatra'
require 'json'

set :port, 4567
set :bind, '0.0.0.0'

# Mandelbrot calculation
def mandelbrot(c_re, c_im, max_iter)
  z_re = 0.0
  z_im = 0.0
  
  max_iter.times do |i|
    return i if z_re * z_re + z_im * z_im > 4.0
    
    z_re_new = z_re * z_re - z_im * z_im + c_re
    z_im = 2.0 * z_re * z_im + c_im
    z_re = z_re_new
  end
  
  max_iter
end

# Generate color from iteration count
def get_color(iterations, max_iter)
  return [0, 0, 0] if iterations == max_iter
  
  hue = (iterations.to_f / max_iter * 360).to_i
  sat = 100
  light = 50
  
  rgb_from_hsl(hue, sat, light)
end

def rgb_from_hsl(h, s, l)
  h = h / 360.0
  s = s / 100.0
  l = l / 100.0
  
  if s == 0
    gray = (l * 255).to_i
    return [gray, gray, gray]
  end
  
  q = l < 0.5 ? l * (1 + s) : l + s - l * s
  p = 2 * l - q
  
  r = hue_to_rgb(p, q, h + 1.0/3)
  g = hue_to_rgb(p, q, h)
  b = hue_to_rgb(p, q, h - 1.0/3)
  
  [(r * 255).to_i, (g * 255).to_i, (b * 255).to_i]
end

def hue_to_rgb(p, q, t)
  t += 1 if t < 0
  t -= 1 if t > 1
  return p + (q - p) * 6 * t if t < 1.0/6
  return q if t < 1.0/2
  return p + (q - p) * (2.0/3 - t) * 6 if t < 2.0/3
  p
end

get '/' do
  erb :index
end

get '/mandelbrot' do
  content_type :json
  
  width = params[:width].to_i
  height = params[:height].to_i
  center_re = params[:center_re].to_f
  center_im = params[:center_im].to_f
  zoom = params[:zoom].to_f
  max_iter = params[:max_iter]&.to_i || 100
  
  range = 3.5 / zoom
  min_re = center_re - range
  max_re = center_re + range
  min_im = center_im - range * height / width
  max_im = center_im + range * height / width
  
  pixels = []
  
  height.times do |y|
    width.times do |x|
      c_re = min_re + (max_re - min_re) * x / width
      c_im = min_im + (max_im - min_im) * y / height
      
      iter = mandelbrot(c_re, c_im, max_iter)
      color = get_color(iter, max_iter)
      
      pixels << color
    end
  end
  
  { pixels: pixels }.to_json
end

__END__

@@index
<!DOCTYPE html>
<html>
<head>
  <title>Mandelbrot Set Viewer</title>
  <style>
    body {
      margin: 0;
      padding: 20px;
      font-family: Arial, sans-serif;
      background: #1a1a1a;
      color: #fff;
    }
    
    h1 {
      margin: 0 0 20px 0;
      font-size: 24px;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
    }
    
    .controls {
      background: #2a2a2a;
      padding: 15px;
      border-radius: 8px;
      margin-bottom: 20px;
    }
    
    .control-group {
      display: inline-block;
      margin-right: 20px;
      margin-bottom: 10px;
    }
    
    label {
      display: inline-block;
      margin-right: 10px;
      font-size: 14px;
    }
    
    button {
      background: #4a9eff;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
    }
    
    button:hover {
      background: #3a8eef;
    }
    
    button:disabled {
      background: #555;
      cursor: not-allowed;
    }
    
    .canvas-container {
      position: relative;
      display: inline-block;
      border: 2px solid #444;
      border-radius: 8px;
      overflow: hidden;
      cursor: crosshair;
    }
    
    canvas {
      display: block;
    }
    
    .info {
      margin-top: 15px;
      font-size: 12px;
      color: #aaa;
    }
    
    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(0, 0, 0, 0.8);
      padding: 20px 40px;
      border-radius: 8px;
      font-size: 18px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🌀 Mandelbrot Set Explorer</h1>
    
    <div class="controls">
      <div class="control-group">
        <button id="zoomIn">Zoom In (+)</button>
        <button id="zoomOut">Zoom Out (-)</button>
      </div>
      <div class="control-group">
        <button id="reset">Reset View</button>
      </div>
      <div class="control-group">
        <label>Iterations:</label>
        <select id="iterations">
          <option value="50">50</option>
          <option value="100" selected>100</option>
          <option value="200">200</option>
          <option value="500">500</option>
        </select>
      </div>
    </div>
    
    <div class="canvas-container">
      <canvas id="canvas" width="800" height="600"></canvas>
      <div class="loading" id="loading" style="display: none;">Rendering...</div>
    </div>
    
    <div class="info">
      <div>Center: (<span id="centerRe">-0.5</span>, <span id="centerIm">0</span>)</div>
      <div>Zoom: <span id="zoomLevel">1</span>x</div>
      <div>Click to center | Scroll to zoom | Click and drag to pan</div>
    </div>
  </div>

  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const loading = document.getElementById('loading');
    
    let centerRe = -0.5;
    let centerIm = 0;
    let zoom = 1;
    let maxIter = 100;
    let isRendering = false;
    let isDragging = false;
    let dragStartX, dragStartY, dragStartRe, dragStartIm;
    
    function updateDisplay() {
      document.getElementById('centerRe').textContent = centerRe.toFixed(6);
      document.getElementById('centerIm').textContent = centerIm.toFixed(6);
      document.getElementById('zoomLevel').textContent = zoom.toFixed(2);
    }
    
    async function render() {
      if (isRendering) return;
      
      isRendering = true;
      loading.style.display = 'block';
      document.querySelectorAll('button').forEach(b => b.disabled = true);
      
      try {
        const response = await fetch(`/mandelbrot?width=${canvas.width}&height=${canvas.height}&center_re=${centerRe}&center_im=${centerIm}&zoom=${zoom}&max_iter=${maxIter}`);
        const data = await response.json();
        
        const imageData = ctx.createImageData(canvas.width, canvas.height);
        
        for (let i = 0; i < data.pixels.length; i++) {
          const idx = i * 4;
          imageData.data[idx] = data.pixels[i][0];
          imageData.data[idx + 1] = data.pixels[i][1];
          imageData.data[idx + 2] = data.pixels[i][2];
          imageData.data[idx + 3] = 255;
        }
        
        ctx.putImageData(imageData, 0, 0);
      } catch (error) {
        console.error('Render error:', error);
      } finally {
        isRendering = false;
        loading.style.display = 'none';
        document.querySelectorAll('button').forEach(b => b.disabled = false);
        updateDisplay();
      }
    }
    
    function pixelToComplex(x, y) {
      const range = 3.5 / zoom;
      const re = centerRe + (x - canvas.width / 2) * range / canvas.width * 2;
      const im = centerIm + (y - canvas.height / 2) * range / canvas.width * 2;
      return { re, im };
    }
    
    canvas.addEventListener('click', (e) => {
      if (isDragging) return;
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const pos = pixelToComplex(x, y);
      centerRe = pos.re;
      centerIm = pos.im;
      render();
    });
    
    canvas.addEventListener('mousedown', (e) => {
      isDragging = false;
      const rect = canvas.getBoundingClientRect();
      dragStartX = e.clientX - rect.left;
      dragStartY = e.clientY - rect.top;
      dragStartRe = centerRe;
      dragStartIm = centerIm;
    });
    
    canvas.addEventListener('mousemove', (e) => {
      if (e.buttons !== 1) return;
      isDragging = true;
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const dx = x - dragStartX;
      const dy = y - dragStartY;
      const range = 3.5 / zoom;
      centerRe = dragStartRe - dx * range / canvas.width * 2;
      centerIm = dragStartIm - dy * range / canvas.width * 2;
    });
    
    canvas.addEventListener('mouseup', () => {
      if (isDragging) {
        render();
      }
      isDragging = false;
    });
    
    canvas.addEventListener('wheel', (e) => {
      e.preventDefault();
      const factor = e.deltaY > 0 ? 0.8 : 1.25;
      zoom *= factor;
      render();
    });
    
    document.getElementById('zoomIn').addEventListener('click', () => {
      zoom *= 2;
      render();
    });
    
    document.getElementById('zoomOut').addEventListener('click', () => {
      zoom *= 0.5;
      render();
    });
    
    document.getElementById('reset').addEventListener('click', () => {
      centerRe = -0.5;
      centerIm = 0;
      zoom = 1;
      render();
    });
    
    document.getElementById('iterations').addEventListener('change', (e) => {
      maxIter = parseInt(e.target.value);
      render();
    });
    
    render();
  </script>
</body>
</html>