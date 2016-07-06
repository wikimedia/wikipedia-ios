var roll = Math.floor((Math.random() * 6) + 1);

setTimeout(function() {
           var dice = document.getElementById("dice");
           dice.className = "roll-" + roll;
           }, 1);