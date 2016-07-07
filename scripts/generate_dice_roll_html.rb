#!/usr/bin/env ruby

output = "<html>
<head>
	<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no\">
	<style>
	body {
		background-color: rgba(0, 0, 0, 0);
	}
	#container {
		position: absolute;
		left: 20px;
		top: 20px;
		height: 50px;
		width: 50px;
		padding: 0 !important;
		perspective: 1000px;
		-webkit-perspective: 1000px;
	}

	#dice {
		cursor: pointer;
		position: absolute;
		transform-style: preserve-3d;
		height: 100%;
		width: 100%;
		-webkit-transform: translateZ( -25px) rotateX( 0deg) rotateY( 0deg) rotateZ( 0deg);
	}

	#dice > div {
		backface-visibility: hidden;
		height: 50px;
		width: 50px;
		position: absolute;
		background: #36c;
		border-radius: 2px;
	}

	#dice > div > span { /*die dot styling */
		position: absolute;
		background: #fff;
		height: 10px;
		width: 10px;
		border-radius: 50%;
		-webkit-transform: translate3d(-50%, -50%, 0);
		backface-visibility: hidden;
	}

	.one {
		-webkit-transform: rotateY( 0deg) translateZ( 25px);
	}

	.two {
		-webkit-transform: rotateX( 180deg) translateZ( 25px);
	}

	.three {
		-webkit-transform: rotateY( 90deg) translateZ( 25px);
	}

	.four {
		-webkit-transform: rotateY( -90deg) translateZ( 25px);
	}

	.five {
		-webkit-transform: rotateX( 90deg) translateZ( 25px);
	}

	.six {
		-webkit-transform: rotateX( -90deg) translateZ( 25px);
	}

	.one span, .three span:nth-child(2), .five span:nth-child(5) {
		top: 50%;
		left: 50%;
	}

	.two span:nth-child(1), .three span:nth-child(1), .four span:nth-child(1), .five span:nth-child(1), .six span:nth-child(1) {
		top: 25%;
		left: 25%;
	}

	.two span:nth-child(2), .three span:nth-child(3), .four span:nth-child(4), .five span:nth-child(4), .six span:nth-child(6) {
		top: 75%;
		left: 75%;
	}

	.four span:nth-child(2), .five span:nth-child(2), .six span:nth-child(2) {
		top: 25%;
		left: 75%;
	}

	.four span:nth-child(3), .five span:nth-child(3), .six span:nth-child(5)  {
		top: 75%;
		left: 25%;
	}

	.six span:nth-child(3) {
		top: 50%;
		left: 25%;
	}   

	.six span:nth-child(4) {
		top: 50%;
		left: 75%;
	}
"

rx = [   0,   0,   0,   0, -90,  90]
ry = [   0, 180, -90,  90,   0,   0]
tz = [ -25, -25, -25, -25, -25, -25]

for i in 0..5
  side = i+1
    output << "

#dice.rolled-#{side} {
    -webkit-transform: translateZ( #{tz[i]}px) rotateX( #{rx[i]}deg) rotateY( #{ry[i]}deg);
}
"
  for j in 0..5
    to_side = j+1
    output << "

#dice.roll-#{side}-#{to_side} {
    -webkit-animation: roll-keyframes-#{side}-#{to_side} 2s 1 linear forwards;
}

@-webkit-keyframes roll-keyframes-#{side}-#{to_side} {
	0% {
		-webkit-transform: translateZ( #{tz[i]}px) rotateX( #{rx[i]}deg) rotateY( #{ry[i]}deg);
	}
	100% {
		-webkit-transform: translateZ( #{tz[j]}px) rotateX( #{rx[j]}deg) rotateY( #{ry[j]}deg);
	}
}

    "
  end
end

output << "
</style>
<body>
	<div id=\"container\">
		<div id=\"dice\" class=\"rolled-1\">
			<div class=\"one\">
				<span></span>
			</div>
			<div class=\"two\">
				<span></span>
				<span></span>
			</div>
			<div class=\"three\">
				<span></span>
				<span></span>
				<span></span>
			</div>
			<div class=\"four\">
				<span></span>
				<span></span>
				<span></span>
				<span></span>
			</div>
			<div class=\"five\">
				<span></span>
				<span></span>
				<span></span>
				<span></span>
				<span></span>
			</div>
			<div class=\"six\">
				<span></span>
				<span></span>
				<span></span>
				<span></span>
				<span></span>
				<span></span>
			</div>
		</div>
	</div>
</body>
"

puts output