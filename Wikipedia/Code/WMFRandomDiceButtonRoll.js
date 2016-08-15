var currentClassName = dice.className;
var split = currentClassName.split("-");
var currentRoll = parseInt(split[split.length - 1]);
var newRoll = currentRoll;
while (newRoll === currentRoll) {
    newRoll = Math.floor((Math.random() * 6) + 1);
}
var variant = Math.floor((Math.random() * 4) + 1);

function doRollAnimation() {
    var dice = document.getElementById("dice");
    if (dice.classList.length == 1) {
        var rolledClassName = "rolled-" + newRoll;
        function setRolledClass(e) {
            e.target.removeEventListener("webkitAnimationEnd", this);
            e.target.className = rolledClassName;
        }
        dice.classList.add("roll-" + currentRoll + "-" + newRoll + "-" + variant);
        dice.addEventListener("webkitAnimationEnd", setRolledClass);
    }
}

setTimeout(doRollAnimation, 1);