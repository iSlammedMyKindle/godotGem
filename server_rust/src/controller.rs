use std::collections::HashSet;

use virtual_gamepad::{GamepadType, GamepadUpdate, VirtualGamepad};

use crate::peer::PeerId;

pub struct Controllers {
    slots: Vec<Controller>,
    limit: usize,
}

impl Controllers {
    pub fn new(limit: usize) -> Self {
        Self {
            slots: Vec::new(),
            limit,
        }
    }

    pub fn assign(&mut self, peer_id: PeerId) -> ControllerId {
        // Attempt to assign an unused controller slot.
        let mut min_index = usize::MAX;
        let mut min_value = usize::MAX;
        for (i, slot) in self.slots.iter_mut().enumerate() {
            if slot.assignees.len() == 0 {
                // occupy first empty slot
                slot.assignees.insert(peer_id);
                return ControllerId(i);
            } else {
                if slot.assignees.len() < min_value {
                    min_index = i;
                    min_value = slot.assignees.len();
                }
            }
        }

        // if this point is reached, no existing slots were empty.
        // if the number of slots is not yet at the limit, add a new
        // slot.
        if self.slots.len() < self.limit {
            let id = ControllerId(self.slots.len());
            let mut assignees = HashSet::new();
            assignees.insert(peer_id);
            self.slots.push(Controller {
                gamepad: VirtualGamepad::new(GamepadType::Xbox360)
                    .expect("Failed to init controller"),
                assignees,
            });
            return id;
        }

        // if this point is reached, there are no available slots and
        // the slot limit has been reached, so we have to start stacking.
        self.slots[min_index].assignees.insert(peer_id);
        ControllerId(min_index)
    }

    pub fn unassign(&mut self, controller: ControllerId, peer: PeerId) {
        if let Some(slot) = self.slots.get_mut(controller.0) {
            slot.assignees.remove(&peer);
        }

        self.pop_leading_unused_controllers();
    }

    pub fn emit(&mut self, controller: ControllerId, update: GamepadUpdate) {
        if let Some(slot) = self.slots.get_mut(controller.0) {
            slot.gamepad.update(update);
        }
    }

    fn pop_leading_unused_controllers(&mut self) {
        while let Some(_) = self.slots.pop_if(|slot| slot.assignees.is_empty()) {}
    }
}

impl Default for Controllers {
    fn default() -> Self {
        Self::new(4)
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Debug)]
pub struct ControllerId(pub usize);

pub struct Controller {
    gamepad: VirtualGamepad,
    assignees: HashSet<PeerId>,
}

impl Controller {}
