import { Zane } from "./app";

console.log("Welcome to Zane!");
let zane = new Zane();
zane.register().then(zane.start.bind(zane));
