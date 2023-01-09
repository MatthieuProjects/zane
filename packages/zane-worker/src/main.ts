import { Zane } from "./app";

console.log("Welcome to Zane!");
const zane = new Zane();
zane.register().then(zane.start.bind(zane));
